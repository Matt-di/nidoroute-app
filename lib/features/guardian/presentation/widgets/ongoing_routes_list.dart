import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/trip.dart';
import '../../../guardian/logic/bloc/guardian_trip_list_bloc.dart';
import '../screens/guardian_tracking_screen.dart';
import 'child_card.dart';

class OngoingRoutesList extends StatelessWidget {
  final List<Passenger> children;
  final bool isLoadingChildren;

  const OngoingRoutesList({
    super.key,
    required this.children,
    required this.isLoadingChildren,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingChildren) {
      return _buildLoadingState();
    }

    if (children.isEmpty) {
      return _buildEmptyState('No children linked to your account');
    }

    return BlocBuilder<GuardianTripListBloc, BlocState<dynamic>>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState();
        }

        if (state.isError) {
          return _buildErrorState(state.errorMessage ?? 'Unknown error');
        }

        if (state.isSuccess && state.data != null) {
          final tripListData = state.data as TripListData;
          final List<Trip> activeTrips = tripListData.trips.where((t) => t.isActive).toList();

          if (activeTrips.isEmpty) {
            return _buildEmptyState('No ongoing trips at the moment');
          }

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                
                // Find trip for this child
                // Match by checking if any delivery in the trip belongs to this child
                Trip? childTrip;
                try {
                  childTrip = activeTrips.firstWhere((trip) {
                    return trip.deliveries?.any((d) => d.passengerId == child.id) ?? false;
                  });
                } catch (e) {
                  childTrip = null;
                }

                // If no active trip specifically for this child, maybe just show the first active trip 
                // if we want to be generous? or just show "No active trip" for this child.
                // But the requirement says "Ongoing Routes", so usually we list the TRIPS.
                // However, the design seems to be Child-centric?
                // Let's stick to the previous logic: Child Card which allows tracking if trip exists.
                
                return ChildCard(
                  child: child,
                  trip: childTrip,
                  onTrackPressed: () {
                    if (childTrip != null) {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GuardianTrackingScreen(
                            trip: childTrip!,
                            focusPassenger: child,
                            allPassengers: children, // Pass all children for sibling logic
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFEE2E2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F1D1D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              message.contains('children') 
                  ? Icons.people_outline_rounded
                  : Icons.directions_bus_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message.contains('children')
                ? 'Add children to your account to get started'
                : 'Active trips will appear here when scheduled',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


