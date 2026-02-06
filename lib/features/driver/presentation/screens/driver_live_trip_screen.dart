import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/utils/map_utils.dart';
import '../../logic/bloc/live_trip_bloc.dart';
import '../../logic/bloc/live_trip_event.dart';
import '../../logic/bloc/live_trip_state.dart';
import '../widgets/live_trip_map_widget.dart';
import '../widgets/simple_trip_stops_sheet.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import 'trip_detail_screen.dart';
import '../../../../core/repositories/trip_repository.dart';
import '../../../../core/services/location_manager.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/trip_tracking_service.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/services/incident_service.dart';
import '../../../admin/presentation/widgets/incident_report_sheet.dart';
import '../../../../core/widgets/user_avatar.dart';

class DriverLiveTripScreen extends StatefulWidget {
  final Trip trip;

  const DriverLiveTripScreen({super.key, required this.trip});

  @override
  State<DriverLiveTripScreen> createState() => _DriverLiveTripScreenState();
}

class _DriverLiveTripScreenState extends State<DriverLiveTripScreen> {
  void _showIncidentReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentReportSheet(
        tripId: widget.trip.id,
        currentLocation: null, // Driver location will be handled by the incident sheet
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LiveTripBloc(
        tripRepository: context.read<TripRepository>(),
        tripTrackingService: context.read<TripTrackingService>(),
        locationManager: LocationManager(),
        iconCache: IconCacheService(),
      )..add(LiveTripStarted(widget.trip)),
      child: _DriverLiveTripContent(trip: widget.trip),
    );
  }
}

class _DriverLiveTripContent extends StatelessWidget {
  final Trip trip;

  const _DriverLiveTripContent({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LiveTripBloc, LiveTripState>(
        listener: (context, state) {
          if (state is LiveTripReady && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
          if (state is LiveTripCompleted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip Completed Successfully!'), backgroundColor: Colors.green),
            );
            
            // Navigate to completed trip detail page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TripDetailScreen(trip: trip),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              const LiveTripMapWidget(),
              
              // Top Overlay (Header)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(context, state),
              ),

              // Bottom Overlay (Controls/Stop Info)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: _buildBottomControls(context, state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncidentReport(context),
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.report_problem),
        label: const Text('Report Incident'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LiveTripState state) {
    String title = 'Trip Details';
    String subtitle = 'Loading...';

    if (state is LiveTripReady) {
      title = state.trip.route?.name ?? 'Active Trip';
      subtitle = 'ROUTE #${state.trip.id.substring(0, 6).toUpperCase()}';
    }

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, letterSpacing: 1.1),
                ),
              ],
            ),
          ),
          if (state is LiveTripReady)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.list_alt_rounded, color: AppTheme.primaryColor),
                  onPressed: () {
                    final bloc = context.read<TripDetailBloc>();
                    print('🛒 DriverLiveTripScreen: List icon pressed. Data: ${state.trip.deliveries?.length ?? 0} deliveries');
                    SimpleTripStopsSheet.show(context, trip: state.trip, bloc: bloc);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.report_problem, color: AppTheme.errorColor),
                  onPressed: () => _showIncidentReport(context),
                  tooltip: 'Report Incident',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, LiveTripState state) {
    if (state is! LiveTripReady) return const SizedBox.shrink();

    final trip = state.trip;
    final nextStop = _getNextPendingStop(state.stops);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (nextStop != null && trip.status == 'in_progress')
          _buildStopCard(context, nextStop, state),
          
        const SizedBox(height: 16),
        
        if (trip.status != 'in_progress')
           _buildStartTripButton(context, state.isSubmitting)
        else if (nextStop == null)
           _buildCompleteTripButton(context, state.isSubmitting),
      ],
    );
  }

  Widget _buildStopCard(BuildContext context, Delivery stop, LiveTripReady state) {
    final isSubmitting = state.isSubmitting;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                imageUrl: stop.passenger?.image,
                name: stop.passengerName ?? 'Unknown Passenger',
                size: 36,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (state.trip.tripType == 'pickup' ? Colors.orange : Colors.red).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  state.trip.tripType == 'pickup' ? Icons.home_rounded : Icons.school_rounded,
                  color: state.trip.tripType == 'pickup' ? Colors.orange : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.trip.tripType == 'pickup' ? 'NEXT PICKUP' : 'NEXT DROP-OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      stop.passengerName ?? 'Unknown Passenger',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (stop.scheduledPickupTime != null)
                Text(
                  _formatTime(stop.scheduledPickupTime!),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  onPressed: isSubmitting ? null : () {
                    if (state.trip.tripType == 'pickup') {
                      context.read<LiveTripBloc>().add(LiveTripPickupRequested(stop));
                    } else {
                      context.read<LiveTripBloc>().add(LiveTripDropoffRequested(stop));
                    }
                  },
                  label: state.trip.tripType == 'pickup' ? 'PICKED UP' : 'DROPPED OFF',
                  color: AppTheme.primaryColor,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              _buildSmallIconButton(
                onPressed: () {
                  final loc = stop.targetLocation(state.trip.tripType);
                  if (loc != null) {
                    MapUtils.openInGoogleMaps(loc.latitude, loc.longitude);
                  }
                },
                icon: Icons.directions_rounded,
                color: Colors.blue,
                tooltip: 'Navigate',
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildActionButton(
                  onPressed: isSubmitting ? null : () {
                    context.read<LiveTripBloc>().add(LiveTripNoShowRequested(stop));
                  },
                  label: 'NO SHOW',
                  color: Colors.grey.shade700,
                  icon: Icons.close_rounded,
                  isOutline: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildStartTripButton(BuildContext context, bool isSubmitting) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : () {
        context.read<LiveTripBloc>().add(LiveTripStartRequested());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      child: isSubmitting 
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text('START TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildCompleteTripButton(BuildContext context, bool isSubmitting) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : () {
        context.read<LiveTripBloc>().add(LiveTripCompleteRequested());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      child: isSubmitting 
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text('COMPLETE TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    required IconData icon,
    bool isOutline = false,
  }) {
    if (isOutline) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Delivery? _getNextPendingStop(List<Delivery> stops) {
    try {
      return stops.firstWhere((s) => s.status == 'pending');
    } catch (_) {
      return null;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showIncidentReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncidentReportSheet(
        tripId: trip.id,
        currentLocation: null, // Driver location will be handled by the incident sheet
      ),
    );
  }
}
