import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import 'package:nitoroute/features/notification/logic/bloc/notification_bloc_simple.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/models/notification_message.dart';
import '../../../../core/models/trip.dart';
import '../../../notification/presentation/screens/notification_list_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/app_button.dart';
import 'manage_drivers_screen.dart';
import 'manage_routes_screen.dart';
import 'manage_passengers_screen.dart';
import 'manage_guardians_screen.dart';
import 'trip_monitoring_screen.dart';
import 'manage_staff_screen.dart';
import '../../../../core/widgets/trip_card.dart';
import '../../../../core/widgets/app_skeleton.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AdminBloc>().add(const AdminLoadDashboardStats());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BlocState<AuthData>>(
      builder: (context, authState) {
        if (!authState.isSuccess || authState.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Header
                  _buildHeader(authState),

                  // AdminBloc Listener for error handling
                  SliverToBoxAdapter(
                    child: BlocConsumer<AdminBloc, AdminState>(
                      listener: (context, state) {
                        if (state is AdminError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error loading dashboard data: ${state.message}',
                              ),
                              backgroundColor: AppTheme.errorColor,
                              action: SnackBarAction(
                                label: 'Retry',
                                textColor: Colors.white,
                                onPressed: () => _loadData(),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        // This builder is just for the listener, actual UI is below
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Quick Actions Section
                  _buildQuickActions(),

                  // Stats Section
                  _buildStats(),

                  // Live Routes Header
                  _buildLiveRoutes(context),

                  // Routes List
                  _buildRouetsList(),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'admin_fab',
            onPressed: _showManagementMenu,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  SliverPadding _buildRouetsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          List<Trip> activeTrips = [];
          bool isLoading = false;

          if (state is AdminLoadingTrips) {
            isLoading = true;
          } else if (state is AdminActiveTripsLoaded) {
            activeTrips = state.trips;
            isLoading = false;
          } else if (state is AdminDashboardStatsLoaded &&
              state.activeTrips != null) {
            activeTrips = state.activeTrips!;
            isLoading = false;
          }

          if (isLoading && activeTrips.isEmpty) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppSkeleton(
                      width: double.infinity,
                      height: 100,
                      borderRadius: BorderRadius.circular(AppTheme.radius12),
                    ),
                  ),
                  childCount: 3,
                ),
              ),
            );
          }

          if (activeTrips.isEmpty) {
            return SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade50,
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade50,
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.route_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Active Routes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All trips are currently completed or scheduled',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check back later for live updates',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final trip = activeTrips[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < activeTrips.length - 1 ? 12 : 24,
                ),
                child: UnifiedTripCard(
                  trip: trip,
                  mode: TripCardMode.admin,
                  isActive: true,
                  showActions: false, // Keep dashboard clean
                  onTap: () {
                    // Navigate to trip monitoring with this trip
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripMonitoringScreen(),
                      ),
                    );
                  },
                ),
              );
            }, childCount: activeTrips.length),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildLiveRoutes(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successColor.withValues(alpha: 0.08),
              AppTheme.successColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Live indicator with pulsing animation
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor,
                    AppTheme.successColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.gps_fixed,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Live Routes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time tracking of active trips',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              text: 'View All',
              variant: AppButtonVariant.outlined,
              height: 48,
              isFullWidth: false,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripMonitoringScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStats() {
    return SliverToBoxAdapter(
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          return Container(
            margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppTheme.primaryColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radius24),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radius12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'System statistics at a glance',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state is AdminLoadingStats)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state is AdminLoadingStats)
                  SizedBox(
                    height: 150,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLoadingStatItem(),
                          const SizedBox(width: 16),
                          _buildLoadingStatItem(),
                          const SizedBox(width: 16),
                          _buildLoadingStatItem(),
                        ],
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatItem(
                          state,
                          'ongoing',
                          'Ongoing',
                          Icons.alt_route,
                          isDark: true,
                        ),
                        const SizedBox(width: 12),
                        _buildStatItem(
                          state,
                          'online_drivers',
                          'Online Drivers',
                          Icons.person_outline,
                        ),
                        const SizedBox(width: 12),
                        _buildStatItem(
                          state,
                          'total_passengers',
                          'Passengers',
                          Icons.people_outline,
                        ),
                        const SizedBox(width: 12),
                        _buildStatItem(
                          state,
                          'total_cars',
                          'Vehicles',
                          Icons.directions_car_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildStatItem(
                          state,
                          'total_routes',
                          'Routes',
                          Icons.route_outlined,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: Icon(
                    Icons.dashboard_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                  Icons.badge_outlined,
                  'Drivers',
                  const ManageDriversScreen(),
                ),
                _buildQuickAction(
                  Icons.map_outlined,
                  'Routes',
                  const ManageRoutesScreen(),
                ),
                _buildQuickAction(
                  Icons.child_care_outlined,
                  'Passengers',
                  const ManagePassengersScreen(),
                ),
                _buildQuickAction(
                  Icons.family_restroom_outlined,
                  'Guardians',
                  const ManageGuardiansScreen(),
                ),
                _buildQuickAction(
                  Icons.monitor_heart_outlined,
                  'Monitor',
                  const TripMonitoringScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeader(BlocState authState) {
    return SliverToBoxAdapter(
      child: BlocConsumer<NotificationBloc, BlocState<List<NotificationMessage>>>(
        listener: (context, notificationState) {},
        builder: (context, notificationState) {
          int unreadCount = 0;
          if (notificationState.isSuccess) {
            unreadCount = notificationState.data!.where((n) => !(n as NotificationMessage).isRead).length;
          }

          return DashboardHeader(
            title: 'Welcome, ${authState.data!.user?.fullName?.split(' ').first ?? 'Admin'}!',
            subtitle: 'DASHBOARD',
            actions: [
              HeaderAction(
                icon: Icons.notifications_none_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationListScreen(),
                    ),
                  );
                },
                badgeCount: unreadCount,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingStatItem() {
    return SizedBox(
      width: 140,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppTheme.radius16),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    AdminState state,
    String key,
    String label,
    IconData icon, {
    bool isDark = false,
  }) {
    String value = '--';
    Map<String, dynamic>? stats;

    // Extract stats from different state types
    if (state is AdminDashboardStatsLoaded) {
      stats = state.stats;
    } else if (state is AdminActiveTripsLoaded) {
      stats = state.stats;
    }

    // Use the stats if available
    if (stats != null) {
      if (key == 'ongoing') {
        value = stats['today']?['active_trips']?.toString() ?? '--';
      } else {
        value =
            stats['overview']?[key]?.toString() ??
            stats[key]?.toString() ??
            '--';
      }
    } else if (state is AdminLoadingStats) {
      value = '...';
    } else if (state is AdminError) {
      value = 'ERR';
    }

    return SizedBox(
      width: 140,
      child: StatCard(title: label, value: value, icon: icon, isDark: isDark),
    );
  }

  void _showManagementMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius24),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radius24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Management Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMenuItem(
                      Icons.badge,
                      'Drivers',
                      const ManageDriversScreen(),
                    ),
                    _buildMenuItem(
                      Icons.map,
                      'Routes',
                      const ManageRoutesScreen(),
                    ),
                    _buildMenuItem(
                      Icons.child_care,
                      'Passengers',
                      const ManagePassengersScreen(),
                    ),
                    _buildMenuItem(
                      Icons.family_restroom,
                      'Guardians',
                      const ManageGuardiansScreen(),
                    ),
                    _buildMenuItem(
                      Icons.monitor_heart,
                      'Trips',
                      const TripMonitoringScreen(),
                    ),
                    _buildMenuItem(
                      Icons.admin_panel_settings,
                      'Staff',
                      const ManageStaffScreen(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radius20),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.primaryColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Widget screen) {
    return SizedBox(
      width: 65,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radius20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
