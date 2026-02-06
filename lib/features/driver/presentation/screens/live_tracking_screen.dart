import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../logic/bloc/live_trip_bloc.dart';
import '../../logic/bloc/live_trip_event.dart';
import '../../logic/bloc/live_trip_state.dart';
import 'trip_detail_screen.dart';

import '../../../../core/services/location_manager.dart';
import '../../../../core/repositories/trip_repository.dart';
import '../../../../core/services/incident_service.dart';
import '../../../../core/services/reverb_service.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/models/trip.dart';

import '../widgets/live_tracking_map_widget.dart';
import '../widgets/simple_trip_stops_sheet.dart';
import '../../../admin/presentation/widgets/incident_report_sheet.dart';

class LiveTrackingScreen extends StatelessWidget {
  final Trip trip;

  const LiveTrackingScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              TripDetailBloc(tripRepository: context.read<TripRepository>())
                ..loadTripDetails(trip.id),
        ),
        BlocProvider(
          create: (context) {
            final bloc = LiveTripBloc(
              tripRepository: context.read<TripRepository>(),
              tripTrackingService: context.read(),
              locationManager: LocationManager(),
              iconCache: context.read(),
            );
            bloc.add(LiveTripStarted(trip));
            return bloc;
          },
        ),
      ],
      child: _LiveTrackingContent(trip: trip),
    );
  }
}

class _LiveTrackingContent extends StatefulWidget {
  final Trip trip;

  const _LiveTrackingContent({required this.trip});

  @override
  State<_LiveTrackingContent> createState() => _LiveTrackingContentState();
}

class _LiveTrackingContentState extends State<_LiveTrackingContent> {
  final LocationManager _locationManager = LocationManager();
  final IncidentService _incidentService = IncidentService();
  final ReverbService _echoService = ReverbService();
  Trip? _completeTrip;
  bool _isCompletingTrip = false;
  StreamSubscription<TripTrackingEvent>? _trackingSubscription;

  void _showIncidentReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentReportSheet(
        tripId: widget.trip.id,
        currentLocation: null, // Location will be handled by the incident sheet
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationManager.stopTracking();
    _trackingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadTrip();
    await _setupWebSocketConnection();
    _setupLocationTracking();
  }

  Future<void> _setupWebSocketConnection() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (!authState.isSuccess || authState.data == null) {
        return;
      }

      final token = authState.data!.token;
      if (token == null) {
        return;
      }

      await _echoService.connect(token);
      
      if (!_echoService.isConnected) {
        return;
      }
      
      final tripTrackingService = context.read<TripTrackingService>();

      tripTrackingService.startTracking(widget.trip.id);
      
      // Listen to trip tracking events
      _trackingSubscription?.cancel();
      _trackingSubscription = tripTrackingService.events.listen((event) {
        if (!mounted) return;
        
        if (event is TripStatusUpdated) {
          _handleTripStatusUpdate(event);
        } else if (event is DeliveryStatusUpdated) {
          _handleDeliveryStatusUpdate(event);
        } else if (event is DriverLocationUpdated) {
          _handleDriverLocationUpdate(event);
        }
      });
    } catch (e) {
    }
  }

  void _handleTripStatusUpdate(TripStatusUpdated event) {
    if (event.tripId != widget.trip.id) return;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip status: ${event.status}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _handleDeliveryStatusUpdate(DeliveryStatusUpdated event) {
    if (event.tripId != widget.trip.id) return;
    
    // Dispatch local update to the Bloc for immediate UI feedback
    context.read<TripDetailBloc>().add(
      TripDeliveryStatusUpdated(
        deliveryId: event.deliveryId,
        status: event.status,
        timestamp: DateTime.now(),
      ),
    );
    
    // Also perform a background sync to ensure data consistency (silently)
    _loadTrip(quiet: true);
  }

  void _handleDriverLocationUpdate(DriverLocationUpdated event) {
    if (event.tripId != widget.trip.id) return;
  }

  Future<void> _loadTrip({bool quiet = false}) async {
    try {
      final tripRepository = context.read<TripRepository>();
      final trip = await tripRepository.getTripById(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _completeTrip = trip;
      });

      context.read<TripDetailBloc>().refreshTripDetails(trip.id, quiet: quiet);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _completeTrip = widget.trip;
      });
    }
  }

  void _setupLocationTracking() {
    final authState = context.read<AuthBloc>().state;
    if (!authState.isSuccess || authState.data == null) return;

    final driverId = authState.data!.user?.driverId;
    if (driverId == null) return;

    _locationManager.startTracking(driverId: driverId, tripId: widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: BlocListener<TripDetailBloc, BlocState<dynamic>>(
        listener: (context, state) {
          // Update trip data when state changes
          if (state.isSuccess && state.data != null) {
            final tripDetailData = state.data as TripDetailData;
            final trip = tripDetailData.trip;
            if (trip.isInProgress || trip.isCompleted) {
              if (trip != _completeTrip) {
                setState(() {
                  _completeTrip = trip;
                });
              }
            }
          }
        },
        child: Column(
          children: [
            _buildModernHeader(context),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12 + MediaQuery.of(context).padding.top,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Live Tracking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Trip in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showIncidentReport,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emergency_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_completeTrip == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
              child: Icon(
                Icons.gps_fixed,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Setting up live tracking',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildStatsSection(),
        Expanded(
          child: Stack(
            children: [const LiveTrackingMapWidget(), _buildFloatingControls()],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.group,
                  label: 'Students',
                  value: '${_completeTrip?.deliveries?.length ?? 0}',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.schedule,
                  label: 'Status',
                  value: 'In Progress',
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trip completion section (shows when all deliveries are completed)
          if (_isAllDeliveriesCompleted())
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Passengers Delivered',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to complete trip',
                          style: TextStyle(
                            color: AppTheme.successColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.successColor, Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isCompletingTrip
                            ? null
                            : () => _showTripCompletionDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: _isCompletingTrip
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Completing...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.flag_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Complete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Regular controls
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showStopDetails(context),
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'View Stops',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement emergency contact
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_in_talk,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Contact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStopDetails(BuildContext context) {
    if (_completeTrip != null) {
      final bloc = context.read<TripDetailBloc>();
      print('🛒 LiveTrackingScreen: Button pressed. Data: ${_completeTrip!.deliveries?.length ?? 0} deliveries');
      SimpleTripStopsSheet.show(context, trip: _completeTrip!, bloc: bloc);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading trip details...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isAllDeliveriesCompleted() {
    if (_completeTrip?.deliveries == null ||
        _completeTrip!.deliveries!.isEmpty) {
      return false;
    }
    return _completeTrip!.deliveries!.every(
      (delivery) =>
          delivery.status == "delivered" || delivery.status == "completed",
    );
  }

  void _showTripCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Trip'),
          content: const Text(
            'Are you sure you want to complete this trip? All passengers have been delivered successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleTripCompletion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Trip'),
            ),
          ],
        );
      },
    );
  }

  void _handleTripCompletion() {
    _performTripCompletion();
  }

  void _performTripCompletion() {
    if (_completeTrip == null) return;

    setState(() => _isCompletingTrip = true);

    // Show progress message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Completing trip...'),
        duration: Duration(seconds: 3),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Listen for completion success or error
    final bloc = context.read<TripDetailBloc>();
    StreamSubscription? subscription;
    subscription = bloc.stream.listen((state) {
      if (state.isSuccess && state.data != null) {
        final tripDetailData = state.data as TripDetailData;
        if (tripDetailData.trip.isCompleted) {
          subscription?.cancel();
          setState(() => _isCompletingTrip = false);

          // Success - navigate to completed trip screen
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip completed successfully!'),
                backgroundColor: AppTheme.successColor,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    TripDetailScreen(trip: tripDetailData.trip),
              ),
            );
          }
        } else if (state.isError) {
          subscription?.cancel();
          setState(() => _isCompletingTrip = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to complete trip: ${state.errorMessage ?? "Unknown error"}',
                ),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    });

    // Send completion request
    bloc.add(TripCompleteRequested(tripId: _completeTrip!.id));

    // Fallback timeout in case state doesn't update
    Future.delayed(const Duration(seconds: 15), () {
      subscription?.cancel();
      if (mounted && _isCompletingTrip) {
        setState(() => _isCompletingTrip = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Trip completion is taking longer than expected. Please check your connection.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }
}
