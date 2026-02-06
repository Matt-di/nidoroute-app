import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../models/trip.dart';

class TripMapPreview extends StatefulWidget {
  final Trip trip;
  final double? height;
  final bool showControls;
  final String? overlayText;

  const TripMapPreview({
    super.key,
    required this.trip,
    this.height,
    this.showControls = false,
    this.overlayText,
  });

  @override
  State<TripMapPreview> createState() => _TripMapPreviewState();
}

class _TripMapPreviewState extends State<TripMapPreview> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    _markers = {};
    _polylines = {};

    if (widget.trip.startLat != null && widget.trip.startLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(widget.trip.startLat!, widget.trip.startLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Trip Start'),
        ),
      );
    }

    if (widget.trip.endLat != null && widget.trip.endLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(widget.trip.endLat!, widget.trip.endLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Trip End'),
        ),
      );
    }

    // Add markers for delivery stops
    final deliveries = widget.trip.deliveries ?? [];
    for (var i = 0; i < deliveries.length; i++) {
      final delivery = deliveries[i];
      if (delivery.pickupLat != null && delivery.pickupLng != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: LatLng(delivery.pickupLat!, delivery.pickupLng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Stop ${delivery.sequence}',
              snippet: delivery.passengerName,
            ),
          ),
        );
      }
    }

    if (_markers.length >= 2) {
      final points = _markers.map((marker) => marker.position).toList();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('trip_route'),
          points: points,
          color: AppTheme.primaryColor,
          width: 4,
        ),
      );
    }
  }

  LatLng _getInitialCameraPosition() {
    if (widget.trip.startLat != null && widget.trip.startLng != null) {
      return LatLng(widget.trip.startLat!, widget.trip.startLng!);
    }

    final deliveries = widget.trip.deliveries ?? [];
    if (deliveries.isNotEmpty && deliveries.first.pickupLat != null && deliveries.first.pickupLng != null) {
      return LatLng(deliveries.first.pickupLat!, deliveries.first.pickupLng!);
    }

    return const LatLng(9.1450, 38.7379); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 220,
      decoration: AppTheme.mapPreviewDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _getInitialCameraPosition(),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                // Fit bounds to show all markers
                if (_markers.isNotEmpty) {
                  _fitBoundsToMarkers();
                }
              },
              zoomControlsEnabled: widget.showControls,
              zoomGesturesEnabled: widget.showControls,
              scrollGesturesEnabled: widget.showControls,
              rotateGesturesEnabled: widget.showControls,
              tiltGesturesEnabled: widget.showControls,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
            if (widget.overlayText != null)
              Positioned(
                top: AppTheme.spacing8,
                right: AppTheme.spacing8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radius4),
                  ),
                  child: Text(
                    widget.overlayText!,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _fitBoundsToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      final position = marker.position;
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    // Add some padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
