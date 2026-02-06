import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';

import '../../../../core/services/guardian_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/quick_action_card.dart';
import '../../../../core/widgets/notification_list_item.dart';

import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../guardian/logic/bloc/guardian_trip_list_bloc.dart';
import '../../../guardian/logic/bloc/guardian_passenger_bloc.dart';
import '../../../guardian/logic/bloc/guardian_passenger_event.dart';
import 'package:nitoroute/features/notification/logic/bloc/notification_bloc_simple.dart';

import '../../../../core/models/passenger.dart';
import '../../../../core/models/notification_message.dart';

import '../widgets/guardian_dashboard_header.dart';
import '../widgets/ongoing_routes_list.dart';
import '../screens/guardian_passenger_list_screen.dart';
import '../screens/guardian_trip_list_screen.dart';
import '../../../notification/presentation/screens/notification_list_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  // final GuardianService _guardianService = GuardianService(); // No longer used locally

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Load passengers via global bloc
    context.read<GuardianPassengerBloc>().add(
      const GuardianPassengerLoadRequested(),
    );
    _loadActiveTrips();
  }

  Future<void> _refreshData() async {
    context.read<GuardianPassengerBloc>().add(
      const GuardianPassengerLoadRequested(forceRefresh: true),
    );
    _loadActiveTrips();
    // Rough wait for visual effect
    await Future.delayed(const Duration(seconds: 1));
  }

  void _loadActiveTrips() {
    context.read<GuardianTripListBloc>().loadGuardianTrips(status: 'active');
  }

  int _activeTripsCount() {
    final state = context.read<GuardianTripListBloc>().state;
    if (state.isSuccess && state.data != null) return state.data!.trips.length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, BlocState<AuthData>>(
          builder: (context, authState) {
            if (!authState.isSuccess || authState.data == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              );
            }
        
            return RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  /// HEADER (Consumes Passenger Bloc)
                  SliverToBoxAdapter(
                    child: BlocBuilder<GuardianPassengerBloc, BlocState<List<Passenger>>>(
                      builder: (context, passengerState) {
                        return GuardianDashboardHeader(
                          children: passengerState.data ?? [],
                          activeTripsCount: _activeTripsCount(),
                        );
                      },
                    ),
                  ),
        
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
        
                  /// ONGOING TRIPS (Consumes Passenger Bloc)
                  SliverToBoxAdapter(
                    child: BlocBuilder<GuardianPassengerBloc, BlocState<List<Passenger>>>(
                      builder: (context, passengerState) {
                        return _ModernSection(
                          title: 'Ongoing Trips',
                          subtitle: 'Track your children in real-time',
                          action: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('View all'),
                          ),
                          child: OngoingRoutesList(
                            children: passengerState.data ?? [],
                            isLoadingChildren: passengerState.isLoading && !passengerState.hasData,
                          ),
                        );
                      }
                    ),
                  ),
        
                  /// QUICK ACTIONS
                  SliverToBoxAdapter(
                    child: _ModernSection(
                      title: 'Quick Actions',
                      subtitle: 'Access frequently used features',
                      child: _buildQuickActions(),
                    ),
                  ),
        
                  /// NOTIFICATIONS
                  SliverToBoxAdapter(
                    child: _ModernSection(
                      title: 'Recent Notifications',
                      subtitle: 'Stay updated with latest activities',
                      action: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationListScreen(),
                          ),
                        ),
                      ),
                      child:
                          BlocBuilder<
                            NotificationBloc,
                            BlocState<List<NotificationMessage>>
                          >(
                            builder: (context, state) {
                               // ... (kept same)
                               List<NotificationMessage> notifications = [];
        
                              if (state.isSuccess && state.data != null) {
                                notifications = state.data!
                                    .take(3)
                                    .toList();
                              }
        
                              if (notifications.isEmpty) {
                                return _buildEmptyNotifications();
                              }
        
                              return Column(
                                children: notifications
                                    .map(
                                      (n) => NotificationListItem(
                                        notification: n,
                                        onTap: () {},
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                    )
                  ),
        
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.people_outline,
                label: 'My Passengers',
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                iconColor: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuardianPassengerListScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: QuickActionCard(
                icon: Icons.history,
                label: 'Trip History',
                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                iconColor: const Color(0xFF3B82F6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuardianTripListScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyNotifications() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll notify you when there are updates',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// --------------------------------------------
/// MODERN SECTION WRAPPER
/// --------------------------------------------
class _ModernSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _ModernSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
