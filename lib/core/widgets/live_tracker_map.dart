import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class LiveTrackerMap extends StatefulWidget {
  final LatLng initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool showUserLocation;
  final Function(GoogleMapController)? onMapCreated;
  final bool followTarget;
  final LatLng? targetPosition;
  final double? targetBearing;
  final double zoom;

  const LiveTrackerMap({
    super.key,
    required this.initialPosition,
    this.markers = const {},
    this.polylines = const {},
    this.showUserLocation = false,
    this.onMapCreated,
    this.followTarget = false,
    this.targetPosition,
    this.targetBearing,
    this.zoom = 16.5,
  });

  @override
  State<LiveTrackerMap> createState() => _LiveTrackerMapState();
}

class _LiveTrackerMapState extends State<LiveTrackerMap> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  GoogleMapController? _mapController;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
  }

  Future<void> _loadMapStyle() async {
    // Optionally load a custom map style (e.g. from assets/map_style.json)
    // For now, we'll use the default look
  }

  @override
  void didUpdateWidget(LiveTrackerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followTarget && widget.targetPosition != null && 
        (widget.targetPosition != oldWidget.targetPosition || 
         widget.targetBearing != oldWidget.targetBearing)) {
      // Only animate camera if position changed significantly (more than 5 meters)
      if (oldWidget.targetPosition == null || 
          _calculateDistance(widget.targetPosition!, oldWidget.targetPosition!) > 5.0) {
        _animateCameraSmoothly(
          widget.targetPosition!, 
          bearing: widget.targetBearing,
        );
      }
    }
  }

  double _calculateDistance(LatLng pos1, LatLng pos2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = pos1.latitude * (math.pi / 180);
    final double lat2Rad = pos2.latitude * (math.pi / 180);
    final double deltaLatRad = (pos2.latitude - pos1.latitude) * (math.pi / 180);
    final double deltaLngRad = (pos2.longitude - pos1.longitude) * (math.pi / 180);

    final double a = math.pow(math.sin(deltaLatRad / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.pow(math.sin(deltaLngRad / 2), 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  Future<void> _animateCameraSmoothly(LatLng position, {double? bearing}) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position, 
          zoom: widget.zoom,
          bearing: bearing ?? 0,
          tilt: 45, // Add a bit of tilt for the premium feel
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 15,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
    );
  }
}
