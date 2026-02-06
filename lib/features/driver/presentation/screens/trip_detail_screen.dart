import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/widgets/trip_map_preview.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/services/trip_service.dart';
import '../widgets/passenger_card.dart';
import 'live_tracking_screen.dart';
import '../../../../core/utils/app_utils.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _isStartingTrip = false;
  Trip? _completeTrip;
  bool _isLoadingTrip = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoadingTrip) {
      _fetchCompleteTripData();
    }
  }

  Future<void> _fetchCompleteTripData() async {
    _isLoadingTrip = false;
    try {
      context.read<TripDetailBloc>().loadTripDetails(widget.trip.id);
      final tripService = context.read<TripService>();
      final completeTrip = await tripService.getTripById(widget.trip.id);
      if (mounted) {
        setState(() {
          _completeTrip = completeTrip;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _completeTrip = widget.trip;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _completeTrip ?? widget.trip;

    return BlocListener<TripDetailBloc, BlocState<dynamic>>(
      listener: (context, state) {
        if (state.isSuccess && state.data != null) {
          final tripDetailData = state.data as TripDetailData;
          if (tripDetailData.trip.isInProgress && tripDetailData.trip.id == trip.id) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LiveTrackingScreen(trip: tripDetailData.trip),
              ),
            );
          } else if (state.isError) {
            setState(() => _isStartingTrip = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating trip: ${state.errorMessage ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            _buildHeader(trip),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTripSummary(trip),
                    _buildStopsSection(trip),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildFixedFooter(trip),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Trip trip) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        MediaQuery.of(context).padding.top + AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.primaryColor,
              size: AppTheme.fontSize24,
            ),
          ),
          Expanded(
            child: Text(
              'Trip #${trip.id.substring(0, 6).toUpperCase()}',
              style: AppTheme.headlineLarge.copyWith(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSize18,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius20),
            ),
            child: Text(
              trip.status.toUpperCase(),
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: AppTheme.fontWeightBold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary(Trip trip) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacing16),
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.route?.name ?? 'Unnamed Route',
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSize18,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: AppTheme.fontSize14,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: AppTheme.spacing4),
                        Text(
                          AppUtils.formatDuration(trip.metrics.plannedDuration),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing12),
                        Container(
                          width: AppTheme.spacing4,
                          height: AppTheme.spacing4,
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacing12),
                        Icon(
                          Icons.route,
                          size: AppTheme.fontSize14,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: AppTheme.spacing4),
                        Text(
                          AppUtils.formatDistance(trip.metrics.plannedDistance),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTheme.spacing16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                  child: TripMapPreview(
                    trip: trip,
                    height: 48,
                    showControls: false,
                  ),
                ),
              ),
            ],
          ),
          if (trip.progress != null) ...[
            SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TRIP PROGRESS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${trip.progress?.completedDeliveries ?? 0}/${trip.progress?.totalDeliveries ?? 0} Stops',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: trip.progress != null && trip.progress!.totalDeliveries > 0 
                    ? (trip.progress!.completedDeliveries / trip.progress!.totalDeliveries).clamp(0.0, 1.0)
                    : 0.0,
                    backgroundColor: Colors.grey.shade200,
                    color: AppTheme.primaryColor,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${trip.progress != null && trip.progress!.totalDeliveries > 0 ? ((trip.progress!.completedDeliveries / trip.progress!.totalDeliveries) * 100).toInt() : 0}% Complete',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopsSection(Trip trip) {
    final deliveries = trip.deliveries ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Text(
            'Stops & Passengers',
            style: AppTheme.headlineLarge.copyWith(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacing16),
        if (deliveries.isEmpty)
          _buildEmptyStops()
        else
          ..._buildStopTimeline(deliveries, trip),
      ],
    );
  }

  Widget _buildEmptyStops() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 32, color: Colors.grey.shade400),
          SizedBox(height: AppTheme.spacing12),
          Text(
            'No stops available',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey.shade600,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStopTimeline(List<Delivery> deliveries, Trip trip) {
    final stops = _groupDeliveriesByStop(deliveries);
    final widgets = <Widget>[];

    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final isLastStop = i == stops.length - 1;

      widgets.add(
        Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineIndicator(isLastStop),
              SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLastStop) 
                      _buildSchoolStopHeader(trip)
                    else 
                      _buildStopHeader(stop, trip),
                    SizedBox(height: AppTheme.spacing12),
                    if (!isLastStop)
                      ...stop.map((delivery) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacing12),
                        child: PassengerCard(
                          delivery: delivery,
                          isPickup: delivery.status.toLowerCase() != 'dropped_off',
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (!isLastStop) {
        widgets.add(SizedBox(height: AppTheme.spacing16));
      }
    }

    return widgets;
  }

  Widget _buildTimelineIndicator(bool isLastStop) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isLastStop ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLastStop ? Icons.school : Icons.location_on,
            color: isLastStop ? AppTheme.textWhite : AppTheme.primaryColor,
            size: 16,
          ),
        ),
        if (!isLastStop)
          Container(
            width: 2,
            height: 64,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
      ],
    );
  }

  Widget _buildSchoolStopHeader(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          '${AppUtils.formatTime(trip.tripDate)} — School',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: AppTheme.fontWeightBold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'End of Route • All students safely dropped',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStopHeader(List<Delivery> stop, Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Text(
          '${AppUtils.formatTime(stop.first.scheduledPickupTime ?? trip.tripDate)} — Stop ${stop.first.sequence}',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: AppTheme.fontWeightBold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${stop.length} ${stop.length == 1 ? 'Passenger' : 'Passengers'}',
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: AppTheme.fontWeightSemiBold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  List<List<Delivery>> _groupDeliveriesByStop(List<Delivery> deliveries) {
    final locationGroups = <String, List<Delivery>>{};
    for (final delivery in deliveries) {
      final locationKey = '${delivery.pickupLat ?? 0}_${delivery.pickupLng ?? 0}';
      locationGroups.putIfAbsent(locationKey, () => []).add(delivery);
    }
    final grouped = locationGroups.values.toList();
    grouped.sort((a, b) {
      final aTime = a.first.scheduledPickupTime ?? DateTime.now();
      final bTime = b.first.scheduledPickupTime ?? DateTime.now();
      return aTime.compareTo(bTime);
    });
    return grouped;
  }

  Widget _buildFixedFooter(Trip trip) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.9),
        border: Border(top: BorderSide(color: AppTheme.textSecondary.withOpacity(0.1), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isStartingTrip ? null : _startTrip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.textWhite,
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius12)),
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isStartingTrip)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              else
                const Icon(Icons.play_circle, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _isStartingTrip ? 'Starting Trip...' : 'Start Trip',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.textWhite, fontWeight: AppTheme.fontWeightBold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTrip() {
    setState(() => _isStartingTrip = true);
    context.read<TripDetailBloc>().startTrip(widget.trip.id);
  }
}
