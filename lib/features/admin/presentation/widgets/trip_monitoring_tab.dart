import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/empty_state.dart';
import 'enhanced_trip_card.dart';

abstract class TripMonitoringTab extends StatelessWidget {
  const TripMonitoringTab({super.key});

  Widget buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => const AppSkeleton(
                height: 120,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onRefresh,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: EmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        action: onRefresh != null
            ? ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  List<Trip> getTripsFromState(AdminState state);
  
  bool isLoading(AdminState state) {
    return state is AdminLoading && getTripsFromState(state).isEmpty;
  }

  bool isEmpty(AdminState state) {
    return getTripsFromState(state).isEmpty;
  }

  Widget buildContent(BuildContext context, List<Trip> trips);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (isLoading(state)) {
          return buildLoadingState();
        }

        final trips = getTripsFromState(state);

        if (trips.isEmpty) {
          return buildEmptyState(
            title: getEmptyTitle(),
            subtitle: getEmptySubtitle(),
            icon: getEmptyIcon(),
            onRefresh: () => onRefresh(context),
          );
        }

        return buildContent(context, trips);
      },
    );
  }

  String getEmptyTitle();
  String getEmptySubtitle();
  IconData getEmptyIcon();
  VoidCallback? onRefresh(BuildContext context) => null;
}
