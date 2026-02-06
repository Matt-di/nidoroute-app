import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../core/utils/map_utils.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/enums/tracking_role.dart';

/// =======================================================
/// Math & Geo helpers
/// =======================================================
class GeoUtils {
  static double bearing(LatLng start, LatLng end) {
    final lat1 = _degToRad(start.latitude);
    final lat2 = _degToRad(end.latitude);
    final dLon = _degToRad(end.longitude - start.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  static double distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _degToRad(double d) => d * math.pi / 180;
  static double _radToDeg(double r) => r * 180 / math.pi;
}

/// =======================================================
/// Delivery helpers
/// =======================================================
class DeliveryUtils {
  static Delivery? nextStop(List<Delivery> deliveries) {
    final pickups = deliveries
        .where((d) => !d.isPickedUp)
        .toList()
      ..sort(_bySequence);

    if (pickups.isNotEmpty) return pickups.first;

    final dropoffs = deliveries
        .where((d) => d.isPickedUp && !d.isDelivered)
        .toList()
      ..sort(_bySequence);

    return dropoffs.isNotEmpty ? dropoffs.first : null;
  }

  static LatLng? resolveTarget(Delivery d) {
    if (!d.isPickedUp && d.pickupLat != null && d.pickupLng != null) {
      return LatLng(d.pickupLat!, d.pickupLng!);
    }
    if (d.isPickedUp && !d.isDelivered && d.dropoffLat != null && d.dropoffLng != null) {
      return LatLng(d.dropoffLat!, d.dropoffLng!);
    }
    return null;
  }

  static int _bySequence(a, b) =>
      (a.sequence ?? 0).compareTo(b.sequence ?? 0);
}

/// =======================================================
/// Marker builder
/// =======================================================
class MarkerBuilder {
  static Set<Marker> build({
    required LatLng busPosition,
    required double bearing,
    required List<Delivery> deliveries,
    Trip? trip,
    TrackingRole role = TrackingRole.driver,
    String? subjectId,
    BitmapDescriptor? busIcon,
    BitmapDescriptor? pickupIcon,
    BitmapDescriptor? dropoffIcon,
    BitmapDescriptor? completedIcon,
    BitmapDescriptor? destinationIcon,
  }) {
    final markers = <Marker>{
      _busMarker(busPosition, bearing, busIcon),
    };

    _addDestination(markers, trip, destinationIcon);
    _addDeliveries(markers, deliveries, role, subjectId, pickupIcon, dropoffIcon, completedIcon);

    return markers;
  }

  static Marker _busMarker(LatLng pos, double bearing, BitmapDescriptor? icon) {
    return Marker(
      markerId: const MarkerId('bus'),
      position: pos,
      rotation: bearing,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Your Location'),
    );
  }

  static void _addDestination(Set<Marker> markers, Trip? trip, BitmapDescriptor? icon) {
    if (trip?.endLat == null || trip?.endLng == null) return;

    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(trip!.endLat!, trip.endLng!),
        icon: icon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Final Destination'),
      ),
    );
  }

  static void _addDeliveries(
    Set<Marker> markers,
    List<Delivery> deliveries,
    TrackingRole role,
    String? subjectId,
    BitmapDescriptor? pickupIcon,
    BitmapDescriptor? dropoffIcon,
    BitmapDescriptor? completedIcon,
  ) {
    for (final d in deliveries) {
      final isSubject = role == TrackingRole.guardian && d.passengerId == subjectId;

      _addPoint(
        markers,
        id: 'pickup_${d.id}',
        lat: d.pickupLat,
        lng: d.pickupLng,
        icon: d.isPickedUp ? completedIcon : pickupIcon,
        title: 'Pickup: ${d.passengerName ?? d.id}',
        highlight: isSubject,
      );

      _addPoint(
        markers,
        id: 'dropoff_${d.id}',
        lat: d.dropoffLat,
        lng: d.dropoffLng,
        icon: d.isDelivered ? completedIcon : dropoffIcon,
        title: 'Dropoff: ${d.passengerName ?? d.id}',
        highlight: isSubject,
      );
    }
  }

  static void _addPoint(
    Set<Marker> markers, {
    required String id,
    required double? lat,
    required double? lng,
    required BitmapDescriptor? icon,
    required String title,
    bool highlight = false,
  }) {
    if (lat == null || lng == null) return;

    markers.add(
      Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        icon: icon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: title),
        zIndex: highlight ? 2 : 1,
      ),
    );
  }
}

/// =======================================================
/// Polyline builder
/// =======================================================
class PolylineBuilder {
  static Future<Set<Polyline>> build({
    required Trip? trip,
    required LatLng? currentPosition,
    required List<Delivery> deliveries,
    required Delivery? nextStop,
    TrackingRole role = TrackingRole.driver,
    String? subjectId,
  }) async {
    final polys = <Polyline>{};

    if (trip?.polyline?.isNotEmpty == true) {
      polys.add(_tripPolyline(trip!));
    } else {
      await _googleRoute(polys, currentPosition, deliveries, trip);
    }

    _highlight(polys, role, currentPosition, deliveries, nextStop, subjectId);

    return polys;
  }

  static Polyline _tripPolyline(Trip trip) {
    return Polyline(
      polylineId: const PolylineId('route'),
      points: MapUtils.decodePolyline(trip.polyline!),
      color: AppTheme.primaryColor.withOpacity(0.3),
      width: 4,
    );
  }

  static Future<void> _googleRoute(
    Set<Polyline> polys,
    LatLng? current,
    List<Delivery> deliveries,
    Trip? trip,
  ) async {
    if (current == null || deliveries.isEmpty) return;

    final points = _optimizedRoute(current, deliveries, trip);
    if (points.length < 2) return;

    final route = await MapsService().getDirections(
      origin: current,
      destination: points.last,
      waypoints: points.length > 2 ? points.sublist(1, points.length - 1) : null,
      travelMode: TravelMode.driving,
    );

    polys.add(
      Polyline(
        polylineId: const PolylineId('google_route'),
        points: route.isNotEmpty ? route : points,
        color: route.isNotEmpty ? Colors.blue : Colors.grey,
        width: route.isNotEmpty ? 5 : 3,
      ),
    );
  }

  static void _highlight(
    Set<Polyline> polys,
    TrackingRole role,
    LatLng? current,
    List<Delivery> deliveries,
    Delivery? nextStop,
    String? subjectId,
  ) {
    if (current == null) return;

    LatLng? target;

    if (role == TrackingRole.guardian && subjectId != null) {
      final d = deliveries.firstWhere(
        (e) => e.passengerId == subjectId,
        orElse: () => deliveries.first,
      );
      target = DeliveryUtils.resolveTarget(d);
    }

    if (role == TrackingRole.driver && nextStop != null) {
      target = DeliveryUtils.resolveTarget(nextStop);
    }

    if (target == null) return;

    polys.add(
      Polyline(
        polylineId: const PolylineId('focus'),
        points: [current, target],
        color: AppTheme.primaryColor,
        width: 5,
        patterns: [PatternItem.dash(12), PatternItem.gap(6)],
      ),
    );
  }

  static List<LatLng> _optimizedRoute(
    LatLng start,
    List<Delivery> deliveries,
    Trip? trip,
  ) {
    final points = <LatLng>[start];

    final ordered = List<Delivery>.from(deliveries)
      ..sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));

    for (final d in ordered) {
      final p = DeliveryUtils.resolveTarget(d);
      if (p != null) points.add(p);
    }

    if (trip?.endLat != null && trip?.endLng != null) {
      points.add(LatLng(trip!.endLat!, trip.endLng!));
    }

    return points;
  }
}