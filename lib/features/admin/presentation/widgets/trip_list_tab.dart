import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_state.dart';
import '../../logic/bloc/admin_event.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import 'trip_monitoring_tab.dart';
import '../../../../core/widgets/trip_card.dart';

class TripListTab extends TripMonitoringTab {
  const TripListTab({super.key});

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
  String getEmptySubtitle() => 'There are no active trips at the moment. All trips are either completed or scheduled.';

  @override
  IconData getEmptyIcon() => Icons.directions_bus_outlined;

  @override
  VoidCallback? onRefresh(BuildContext context) {
    return () => context.read<AdminBloc>().add(const AdminLoadActiveTrips());
  }

  @override
  Widget buildContent(BuildContext context, List<Trip> trips) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(const AdminLoadActiveTrips()),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverList.separated(
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return UnifiedTripCard(
                  trip: trip,
                  mode: TripCardMode.admin,
                  isActive: true,
                  isViewOnly: false, // Set to true for admin tracking view-only mode
                  onTap: () {
                    // Navigate to trip details or live tracking based on status
                    if (trip.status.toLowerCase() == 'in_progress' || 
                        trip.status.toLowerCase() == 'active') {
                      // Navigate to live tracking
                    } else {
                      // Navigate to trip details
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
