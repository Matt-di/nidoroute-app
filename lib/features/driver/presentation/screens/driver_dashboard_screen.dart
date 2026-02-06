import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/simple_trip_card.dart';
import 'live_tracking_screen.dart';
import 'trip_detail_screen.dart';
import '../../../../../core/widgets/app_skeleton.dart';
import '../widgets/trip_metric_card.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
    _setStatusBarColor();
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when coming back to this screen
    final tripState = context.read<TripBloc>().state;
    if (tripState.isInitial || tripState.isError) {
      _loadData();
    }
  }

  void _loadData({Completer<void>? completer}) {
    context.read<TripBloc>().add(TripListLoadRequested(type: TripListType.driverDashboard));
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
          backgroundColor: AppTheme.primaryColor,
          body: Column(
            children: [
              _buildModernDashboardHeader(authState.data!.user?.fullName ?? 'Driver'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final completer = Completer<void>();
                    _loadData(completer: completer);
                    return completer.future;
                  },
                  color: AppTheme.primaryColor,
                  child: BlocBuilder<TripBloc, BlocState<dynamic>>(
                    builder: (context, tripState) {
                      return CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          
                          /// DRIVER STATS SECTION
                          SliverToBoxAdapter(
                            child: _DriverSection(
                              title: 'Today\'s Overview',
                              subtitle: 'Track your daily performance',
                              child: _buildPremiumStatsRow(tripState),
                            )
                               
                          ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          
                          /// ACTIVE TRIPS SECTION
                          if (tripState.isSuccess && tripState.data != null &&
                              (tripState.data as TripListData).trips.any((t) => t.isInProgress))
                            SliverToBoxAdapter(
                              child: _DriverSection(
                                title: 'Active Trips',
                                subtitle: 'Currently in progress',
                                action: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.successColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.successColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: AppTheme.successColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                child: _buildActiveTripSection(tripState),
                              )
                      
                            ),
                          
                          if (tripState.isSuccess && tripState.data != null &&
                              (tripState.data as TripListData).trips.any((t) => t.isInProgress))
                            const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          
                          /// PENDING TRIPS SECTION
                          SliverToBoxAdapter(
                            child: _DriverSection(
                              title: 'Pending Trips',
                              subtitle: 'Upcoming scheduled trips',
                              child: _buildPendingTripsSection(tripState),
                            )
                            
                          ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernDashboardHeader(String fullName) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20 + MediaQuery.of(context).padding.top, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryColor,
            AppTheme.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?u=driver'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Hello, ${fullName.split(' ')[0]}!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Driver Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Online & Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFECACA),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emergency_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatsRow(BlocState<dynamic> state) {
    Map<String, dynamic>? stats;
    if (state.isSuccess && state.data != null) {
      final tripListData = state.data as TripListData?;
      stats = tripListData?.driverStats;
    }

    final totalTrips = stats?['stats']?['total_trips']?.toString() ?? '0';
    final String tripsToday = stats?['today']?['count']?.toString() ?? '0';

    return Row(
      children: [
        Expanded(
          child: TripMetricCard(
            label: 'TODAY',
            value: '$tripsToday Trips',
            icon: Icons.calendar_today_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TripMetricCard(
            label: 'TOTAL',
            value: '$totalTrips Trips',
            icon: Icons.history_rounded,
            color: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripSection(BlocState<dynamic> state) {
    if (!state.isSuccess || state.data == null) return const SizedBox.shrink();

    final tripListData = state.data as TripListData?;
    final activeTrips = tripListData?.trips.where((t) => t.status == 'in_progress').toList() ?? [];

    return Column(
      children: [
        ...activeTrips.map((trip) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SimpleTripCard(
            trip: trip,
            mode: SimpleTripCardMode.driver,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveTrackingScreen(trip: trip),
              ),
            ),
            onPrimaryAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LiveTrackingScreen(trip: trip),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPendingTripsSection(BlocState<dynamic> state) {
    if (state.isLoading) {
      return const AppSkeletonList(itemCount: 2, padding: EdgeInsets.zero);
    }

    final tripListData = state.isSuccess && state.data != null 
        ? state.data as TripListData 
        : null;
    final pendingTrips = tripListData?.trips.where((t) => t.status == 'scheduled').toList() ?? [];

    if (pendingTrips.isEmpty) {
      return _buildEmptyTripsCard();
    }

    return Column(
      children: [
        ...pendingTrips.map((trip) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SimpleTripCard(
            trip: trip,
            mode: SimpleTripCardMode.driver,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
            ),
            onPrimaryAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyTripsCard() {
    return Container(
      width: double.infinity,
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
              Icons.event_available_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending trips for today.',
            style: TextStyle(
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

/// --------------------------------------------
/// DRIVER SECTION WIDGET
/// --------------------------------------------
class _DriverSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _DriverSection({
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
