import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/map_utils.dart';
import '../screens/modern_trip_detail_screen.dart';
import 'trip_monitoring_tab.dart';

class TripMapTab extends TripMonitoringTab {
  const TripMapTab({super.key});

  @override
  List<Trip> getTripsFromState(AdminState state) {
    if (state is AdminActiveTripsLoaded) {
      return state.trips;
    } else if (state is AdminDashboardStatsLoaded && state.activeTrips != null) {
      return state.activeTrips!;
    }
    return [];
  }

  @override
  String getEmptyTitle() => 'No Active Trips';

  @override
  String getEmptySubtitle() => 'There are no active trips to display on the map. Start a trip to see real-time tracking.';

  @override
  IconData getEmptyIcon() => Icons.map_outlined;

  @override
  Widget buildContent(BuildContext context, List<Trip> trips) {
    return _TripMapView(trips: trips);
  }
}

class _TripMapView extends StatefulWidget {
  final List<Trip> trips;

  const _TripMapView({required this.trips});

  @override
  State<_TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<_TripMapView> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMapAssets();
    _updateMapData();
  }

  @override
  void didUpdateWidget(_TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trips != widget.trips) {
      _updateMapData();
    }
  }

  Future<void> _loadMapAssets() async {
    try {
      _busIcon = await MapUtils.getBytesFromAsset(
        'assets/images/bus_marker.png',
        80,
      );
      setState(() {});
    } catch (e) {
      // Fallback to default marker if asset fails to load
      _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _updateMapData() {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    for (final trip in widget.trips) {
      if (trip.startLat != null && trip.startLng != null) {
        final marker = Marker(
          markerId: MarkerId('trip_${trip.id}'),
          position: LatLng(trip.startLat!, trip.startLng!),
          icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Route ${trip.route?.name ?? 'Unknown'}',
            snippet: 'Status: ${trip.status?.toUpperCase() ?? 'UNKNOWN'}',
          ),
          onTap: () => _showTripDetails(trip),
        );
        markers.add(marker);
      }

      // Add polyline if route coordinates are available
      if (trip.route?.coordinates?.isNotEmpty == true) {
        final polyline = Polyline(
          polylineId: PolylineId('route_${trip.id}'),
          points: trip.route!.coordinates!
              .map((coord) => LatLng(coord.latitude, coord.longitude))
              .toList(),
          color: _getRouteColor(trip.status),
          width: 4,
          patterns: [PatternItem.dash(10)],
        );
        polylines.add(polyline);
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Adjust camera to show all markers
    if (_markers.isNotEmpty && _mapController != null) {
      _fitAllMarkers();
    }
  }

  Color _getRouteColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in_progress':
      case 'active':
        return AppTheme.successColor;
      case 'scheduled':
        return AppTheme.warningColor;
      case 'completed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _markers.map((m) => m.position.latitude).reduce((a, b) => a < b ? a : b),
        _markers.map((m) => m.position.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        _markers.map((m) => m.position.latitude).reduce((a, b) => a > b ? a : b),
        _markers.map((m) => m.position.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void _showTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius24)),
      ),
      isScrollControlled: true,
      builder: (context) => _TripDetailsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Active Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no active trips to display on the map. Start a trip to see real-time tracking.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.trips.isNotEmpty && widget.trips.first.startLat != null
            ? LatLng(widget.trips.first.startLat!, widget.trips.first.startLng!)
            : const LatLng(0, 0),
        zoom: 12,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_markers.isNotEmpty) {
          _fitAllMarkers();
        }
      },
    );
  }
}

class _TripDetailsSheet extends StatelessWidget {
  final Trip trip;

  const _TripDetailsSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route ${trip.route?.name ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Status: ${trip.status?.toUpperCase() ?? 'UNKNOWN'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (trip.driver?.fullName != null) ...[
            _buildInfoRow(Icons.person, 'Driver', trip.driver!.fullName ?? 'Unknown'),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(Icons.route, 'Route', trip.route?.name ?? 'Unknown'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.schedule, 'Status', trip.status ?? 'Unknown'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModernTripDetailScreen(trip: trip),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius12),
                ),
              ),
              child: const Text('View Full Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
