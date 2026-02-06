import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../../../core/services/reverb_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../core/widgets/live_tracker_map.dart';
import '../../../../core/services/incident_service.dart';
import '../widgets/incident_resolution_sheet.dart';
import 'modern_trip_detail_screen.dart';

class AdminLiveTrackingScreen extends StatefulWidget {
  final Trip trip;

  const AdminLiveTrackingScreen({
    super.key,
    required this.trip,
  });

  @override
  State<AdminLiveTrackingScreen> createState() => _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final ReverbService _echoService = ReverbService();
  final IconCacheService _iconCache = IconCacheService();
  bool _isWebSocketConnected = false;
  bool _iconsLoaded = false;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initializeIcons();
    _initializeMap();
    _connectWebSocket();
  }

  Future<void> _initializeIcons() async {
    if (!_iconCache.isReady) {
      await _iconCache.initialize();
    }
    if (mounted) {
      setState(() {
        _iconsLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _echoService.leave('trip.${widget.trip.id}');
    _mapController?.dispose();
    super.dispose();
  }

  void _connectWebSocket() async {
    try {
      // Get auth token from AuthService
      final authService = AuthService();
      final authToken = await authService.getToken();
      
      if (authToken == null) {
        print('No auth token available for WebSocket connection');
        return;
      }
      
      await _echoService.connect(authToken);
      
      setState(() {
        _isWebSocketConnected = true;
      });
      
      // Listen for real-time trip updates
      _echoService.private('trip.${widget.trip.id}', SocketEvents.tripLocationUpdated, (data) {
        _handleLocationUpdate(data);
      });
      
      _echoService.private('trip.${widget.trip.id}', SocketEvents.tripStatusUpdated, (data) {
        _handleStatusUpdate(data);
      });
      
      _echoService.private('trip.${widget.trip.id}', SocketEvents.deliveryStatusUpdated, (data) {
        _handlePassengerUpdate(data);
      });
      
      }
    } catch (e) {
      print('WebSocket connection failed: $e');
      setState(() {
        _isWebSocketConnected = false;
      });
    }
  }

  void _handleLocationUpdate(dynamic data) {
    // Handle real-time location updates
    if (mounted && data['location'] != null) {
      final location = data['location'];
      final lat = location['latitude'];
      final lng = location['longitude'];
      
      if (lat != null && lng != null) {
        final newLocation = LatLng(lat, lng);
        
        setState(() {
          _routePoints.add(newLocation);
          
          _markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
          _markers.add(
            Marker(
              markerId: const MarkerId('driver_location'),
              position: newLocation,
              infoWindow: InfoWindow(
                title: 'Driver Location',
                snippet: 'Last updated: ${DateTime.now().toString().substring(11, 19)}',
              ),
              icon: _iconCache.icons.bus ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              rotation: location['heading']?.toDouble() ?? 0.0, // Car rotation based on heading
              anchor: const Offset(0.5, 0.5), // Center the icon on the location
            ),
          );
          
          _drawRoutePolyline();
          
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 16),
          );
        });
      }
    }
  }

  void _drawRoutePolyline() {
    if (_routePoints.length < 2) return;
    
    setState(() {
      _polylines.removeWhere((polyline) => polyline.polylineId.value == 'route_path');
      
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: _routePoints,
          color: AppTheme.primaryColor,
          width: 4,
          patterns: [PatternItem.dash(10)], // Dashed line for route
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    });
  }

  void _initializeRoute() {
    if (widget.trip.route?.coordinates?.isNotEmpty == true) {
      final routeCoords = widget.trip.route!.coordinates!;
      setState(() {
        _routePoints = routeCoords
            .map((coord) => LatLng(coord.latitude, coord.longitude))
            .toList();
        _drawRoutePolyline();
      });
    } else if (widget.trip.startLat != null && widget.trip.startLng != null) {
      // Fallback to start location
      setState(() {
        _routePoints = [LatLng(widget.trip.startLat!, widget.trip.startLng!)];
      });
    }
  }

  void _fitAllMarkers() {
    if (_mapController == null || _markers.isEmpty) return;

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

  void _handleStatusUpdate(dynamic data) {
    if (mounted && data['status'] != null) {
      setState(() {
        // Update trip status in UI
        // You might want to update the trip object or trigger a refresh
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status updated to: ${data['status']}'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handlePassengerUpdate(dynamic data) {
    // Handle passenger pickup/dropoff updates
    if (mounted && data['passenger_count'] != null) {
      setState(() {
        // Update passenger count display
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passenger update: ${data['event']}'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  final IncidentService _incidentService = IncidentService();

  void _showIncidentResolution() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentResolutionSheet(
        tripId: widget.trip.id,
        onResolve: (incidentId, resolutionNotes) async {
          try {
            await _incidentService.resolveIncident(
              incidentId: incidentId,
              resolutionNotes: resolutionNotes,
            );
            
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Incident resolved successfully')),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Error: ${e.toString()}')),
                    ],
                  ),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _initializeMap() {
    // Initialize route with trip coordinates
    _initializeRoute();
    
    // Add initial trip marker
    if (widget.trip.startLat != null && widget.trip.startLng != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('trip_${widget.trip.id}'),
          position: LatLng(widget.trip.startLat!, widget.trip.startLng!),
          infoWindow: InfoWindow(
            title: '${widget.trip.route?.name ?? 'Trip'}',
            snippet: 'Status: ${widget.trip.status?.toUpperCase() ?? 'UNKNOWN'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Map View - using existing LiveTrackerMap widget
          LiveTrackerMap(
            initialPosition: widget.trip.startLat != null && widget.trip.startLng != null
                ? LatLng(widget.trip.startLat!, widget.trip.startLng!)
                : const LatLng(0, 0),
            markers: _markers,
            polylines: _polylines,
            showUserLocation: true,
            followTarget: _routePoints.isNotEmpty,
            targetPosition: _routePoints.isNotEmpty ? _routePoints.last : null,
            zoom: 16,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_routePoints.isNotEmpty) {
                _fitAllMarkers();
              }
            },
          ),

          // Top Info Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trip.route?.name ?? 'Live Tracking',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Driver: ${widget.trip.driver?.fullName ?? 'Unknown'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isWebSocketConnected ? AppTheme.successColor : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isWebSocketConnected ? 'LIVE' : 'CONNECTING...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Trip Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trip Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.gps_fixed,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip In Progress',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Started at ${widget.trip.actualStartTime != null ? widget.trip.actualStartTime!.toString().substring(11, 16) : 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.trip.metrics.actualPassengers}/${widget.trip.metrics.plannedPassengers}',
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress Bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: widget.trip.progress?.percentageComplete != null
                            ? (widget.trip.progress!.percentageComplete / 100).clamp(0.0, 1.0)
                            : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModernTripDetailScreen(trip: widget.trip),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Trip Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(color: AppTheme.primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Contact driver functionality
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Contact Driver'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showIncidentResolution,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Resolve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIncidentResolution,
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_circle),
        label: const Text('Resolve Incident'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}
