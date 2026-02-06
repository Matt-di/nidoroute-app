import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:nitoroute/core/widgets/trip_card.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/delivery.dart';
import '../../../../core/models/trip_status_info.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../widgets/admin_trip_map_widget.dart';

class ModernTripDetailScreen extends StatefulWidget {
  final Trip trip;

  const ModernTripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ModernTripDetailScreen> createState() => _ModernTripDetailScreenState();
}

class _ModernTripDetailScreenState extends State<ModernTripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripStatus = _getTripStatusInfo();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(tripStatus),
            _buildSliverTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(tripStatus),
            _buildPassengersTab(),
            _buildMapTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(tripStatus),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildSliverAppBar(TripStatusInfo status) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: status.color,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                status.color,
                status.color.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          status.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.trip.route?.name ?? 'Unnamed Route',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickStat(
                        Icons.people,
                        '${widget.trip.metrics.actualPassengers}/${widget.trip.metrics.plannedPassengers}',
                        'Passengers',
                      ),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        Icons.access_time,
                        _formatDuration(),
                        'Duration',
                      ),
                      const SizedBox(width: 16),
                      _buildQuickStat(
                        Icons.route,
                        '${widget.trip.metrics.actualDistance.toStringAsFixed(1)}km',
                        'Distance',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => context.read<TripDetailBloc>().refreshTripDetails(widget.trip.id),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Trip'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Export Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('Share Trip'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Passengers',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Map',
            ),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildOverviewTab(TripStatusInfo status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Section
          _buildTimelineSection(status),
          const SizedBox(height: 24),

          // Driver & Vehicle Info
          Row(
            children: [
              Expanded(child: _buildDriverCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildVehicleCard()),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Section
          _buildProgressCard(),
          const SizedBox(height: 24),

          // Route Details
          _buildRouteDetailsCard(),
          const SizedBox(height: 24),

          // Actions Section
          _buildActionsSection(status),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(TripStatusInfo status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.timeline, color: status.color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Trip Timeline',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Scheduled Start',
            widget.trip.scheduledStartTime ?? 'Not set',
            Icons.schedule,
            Colors.blue,
            isFirst: true,
          ),
          _buildTimelineItem(
            'Actual Start',
            widget.trip.actualStartTime != null
                ? DateFormat('h:mm a').format(widget.trip.actualStartTime!)
                : 'Not started',
            Icons.play_arrow,
            status.color,
          ),
          _buildTimelineItem(
            'Estimated End',
            widget.trip.scheduledEndTime ?? 'Not set',
            Icons.schedule,
            Colors.grey,
          ),
          _buildTimelineItem(
            'Actual End',
            widget.trip.actualEndTime != null
                ? DateFormat('h:mm a').format(widget.trip.actualEndTime!)
                : 'Not completed',
            Icons.flag,
            widget.trip.status.toLowerCase() == 'completed' ? Colors.green : Colors.grey,
            isLast: true,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin:  EdgeInsets.only(bottom: isLast ? 0 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              UserAvatarWithBorder(
                imageUrl: widget.trip.driver?.avatar,
                name: widget.trip.driver?.fullName ?? 'Unassigned Driver',
                size: 48,
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderWidth: 2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.trip.driver?.fullName ?? 'Unassigned',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.trip.driver?.phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  widget.trip.driver!.phone!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Assigned Vehicle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Capacity: ${widget.trip.car?.capacity ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildProgressCard() {
    final progress = widget.trip.progress;
    if (progress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Trip Progress',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${progress.percentageComplete.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.percentageComplete / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat(
                'Total',
                '${progress.totalDeliveries}',
                Icons.list_alt,
                Colors.grey,
              ),
              _buildProgressStat(
                'Completed',
                '${progress.completedDeliveries}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildProgressStat(
                'Pending',
                '${progress.pendingDeliveries}',
                Icons.schedule,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.route, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Route Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Route Name', widget.trip.route?.name ?? 'Not assigned'),
          _buildDetailRow('Description', widget.trip.route?.description ?? 'No description'),
          _buildDetailRow('Estimated Duration', '${widget.trip.metrics.plannedDuration} minutes'),
          _buildDetailRow('Distance', '${widget.trip.metrics.actualDistance.toStringAsFixed(1)} km'),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(TripStatusInfo status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: status.key == 'in_progress' ? 'Live Tracking' : 'View Details',
                  onPressed: () {
                    if (status.key == 'in_progress') {
                      // Navigate to live tracking
                    } else {
                      // Show more details
                    }
                  },
                  variant: AppButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Contact Driver',
                  onPressed: () {
                    // Show contact options
                  },
                  variant: AppButtonVariant.outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPassengersTab() {
    final deliveries = widget.trip.deliveries;
    
    if (deliveries == null || deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No passengers assigned',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Passengers will appear here once assigned to this trip',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: deliveries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return _buildPassengerCard(delivery, index);
      },
    );
  }

  Widget _buildPassengerCard(Delivery delivery, int index) {
    final statusColor = _getDeliveryStatusColor(delivery.status);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sequence Number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Passenger Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                      imageUrl: delivery.passenger?.image,
                      name: delivery.passengerName ?? 'Unknown Passenger',
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        delivery.passengerName ?? 'Unknown Passenger',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sequence #${delivery.sequence}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (delivery.scheduledPickupTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pickup: ${DateFormat('h:mm a').format(delivery.scheduledPickupTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getDeliveryStatusText(delivery.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildMapTab() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: const AdminTripMapWidget(),
      ),
    );
  }

  Widget _buildFloatingActionButton(TripStatusInfo status) {
    if (status.key != 'scheduled') return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton.extended(
        onPressed: () {
          // Start trip action
        },
        backgroundColor: status.color,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
      ),
    );
  }

  // Helper methods
  TripStatusInfo _getTripStatusInfo() {
    switch (widget.trip.status.toLowerCase()) {
      case 'active':
      case 'in_progress':
        return TripStatusInfo(
          key: 'in_progress',
          label: 'IN PROGRESS',
          color: AppTheme.successColor,
          icon: Icons.gps_fixed,
        );
      case 'completed':
        return TripStatusInfo(
          key: 'completed',
          label: 'COMPLETED',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'scheduled':
        return TripStatusInfo(
          key: 'scheduled',
          label: 'SCHEDULED',
          color: AppTheme.warningColor,
          icon: Icons.schedule,
        );
      case 'cancelled':
        return TripStatusInfo(
          key: 'cancelled',
          label: 'CANCELLED',
          color: AppTheme.errorColor,
          icon: Icons.cancel,
        );
      default:
        return TripStatusInfo(
          key: 'unknown',
          label: widget.trip.status.toUpperCase(),
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }

  String _getDriverInitials() {
    final driver = widget.trip.driver;
    if (driver?.fullName != null) {
      final names = driver!.fullName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0][0].toUpperCase();
      }
    }
    return 'D';
  }

  String _formatDuration() {
    final duration = widget.trip.metrics.actualDuration > 0
        ? widget.trip.metrics.actualDuration
        : widget.trip.metrics.plannedDuration;
    
    if (duration > 0) {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }
    return '--';
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'picked_up':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getDeliveryStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'picked_up':
        return 'Picked Up';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Edit trip
        break;
      case 'export':
        // Export trip details
        break;
      case 'share':
        // Share trip
        break;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
