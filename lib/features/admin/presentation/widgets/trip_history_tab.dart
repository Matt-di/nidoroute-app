import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_state.dart';
import '../../logic/bloc/admin_event.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_badge.dart';
import '../screens/modern_trip_detail_screen.dart';
import 'trip_monitoring_tab.dart';
import '../../../../core/widgets/trip_card.dart';

class TripHistoryTab extends TripMonitoringTab {
  const TripHistoryTab({super.key});

  @override
  List<Trip> getTripsFromState(AdminState state) {
    if (state is AdminAllTripsLoaded) {
      return state.trips;
    }
    return [];
  }

  @override
  String getEmptyTitle() => 'No Trip History';

  @override
  String getEmptySubtitle() => 'No completed or historical trips found. Trip history will appear here once trips are completed.';

  @override
  IconData getEmptyIcon() => Icons.history_outlined;

  @override
  VoidCallback? onRefresh(BuildContext context) {
    return () => context.read<AdminBloc>().add(const AdminLoadAllTrips());
  }

  @override
  Widget buildContent(BuildContext context, List<Trip> trips) {
    return RefreshIndicator(
      onRefresh: () async => context.read<AdminBloc>().add(const AdminLoadAllTrips()),
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverList.separated(
              itemCount: trips.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return UnifiedTripCard(
                  trip: trip,
                  mode: TripCardMode.admin,
                  isActive: false,
                  showActions: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModernTripDetailScreen(trip: trip),
                      ),
                    );
                  },
                  onDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModernTripDetailScreen(trip: trip),
                      ),
                    );
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
