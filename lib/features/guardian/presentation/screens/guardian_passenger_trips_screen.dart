import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/models/delivery.dart';
import 'package:intl/intl.dart';

class GuardianPassengerTripsScreen extends StatefulWidget {
  final Passenger passenger;

  const GuardianPassengerTripsScreen({super.key, required this.passenger});

  @override
  State<GuardianPassengerTripsScreen> createState() =>
      _GuardianPassengerTripsScreenState();
}

class _GuardianPassengerTripsScreenState
    extends State<GuardianPassengerTripsScreen> {
  final DeliveryService _deliveryService = DeliveryService();
  List<Delivery> _deliveries = [];
  bool _isLoading = true;

  // Filter options
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All Time';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Picked Up',
    'Delivered',
    'No Show',
    'Cancelled',
  ];
  final List<String> _dateRangeOptions = [
    'All Time',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
  ];

  @override
  void initState() {
    super.initState();
    _loadPassengerDeliveries();
  }

  Future<void> _loadPassengerDeliveries() async {
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState.isSuccess && authState.data != null) {
        final deliveries = await _deliveryService.getGuardianDeliveries(
          status: _selectedStatus,
          dateRange: _selectedDateRange,
          passengerId: widget.passenger.id,
        );
        if (mounted) {
          setState(() {
            _deliveries = deliveries;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trip history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              title: '${widget.passenger.firstName}\'s Trips',
              subtitle: 'Trip history and delivery records',
              
              showBackButton: true,
              actions: [
                HeaderAction(
                  icon: Icons.filter_list,
                  onPressed: _showFilterModal,
                ),
                HeaderAction(
                  icon: Icons.refresh,
                  onPressed: _loadPassengerDeliveries,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _deliveries.isEmpty
                  ? _buildEmptyState()
                  : _buildDeliveriesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Trip History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.passenger.firstName} hasn\'t had any trips yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList() {
    // Group deliveries by date
    final groupedDeliveries = _groupDeliveriesByDate(_deliveries);

    return RefreshIndicator(
      onRefresh: _loadPassengerDeliveries,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: groupedDeliveries.length,
        itemBuilder: (context, index) {
          final dateKey = groupedDeliveries.keys.elementAt(index);
          final deliveries = groupedDeliveries[dateKey]!;
          final dateGroup = MapEntry(dateKey, deliveries);
          return _buildDateGroup(dateGroup);
        },
      ),
    );
  }

  Map<String, List<Delivery>> _groupDeliveriesByDate(
    List<Delivery> deliveries,
  ) {
    final grouped = <String, List<Delivery>>{};

    for (final delivery in deliveries) {
      final date = delivery.scheduledPickupTime ?? delivery.actualPickupTime;
      if (date != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        grouped.putIfAbsent(dateKey, () => []).add(delivery);
      }
    }

    // Sort deliveries within each date group (most recent first)
    grouped.forEach((key, value) {
      value.sort((a, b) {
        final aTime = a.scheduledPickupTime ?? DateTime.now();
        final bTime = b.scheduledPickupTime ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
    });

    // Sort date groups (most recent first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  Widget _buildDateGroup(MapEntry<String, List<Delivery>> dateGroup) {
    final date = DateTime.parse(dateGroup.key);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
      date,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM dd').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Container(
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),

        // Delivery Cards
        ...dateGroup.value.map((delivery) => _buildDeliveryCard(delivery)),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeliveryCard(Delivery delivery) {
    final statusColor = _getStatusColor(delivery.status);
    final statusIcon = _getStatusIcon(delivery.status);
    final isCompleted = delivery.status.toLowerCase() == 'delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.white, Colors.green.shade50.withOpacity(0.3)]
              : [Colors.white, Colors.grey.shade50.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status Badge and Time
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(delivery.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Time Display
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.scheduledPickupTime != null
                        ? DateFormat(
                            'h:mm a',
                          ).format(delivery.scheduledPickupTime!)
                        : 'TBD',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Timeline Progress
            _buildTimelineProgress(delivery),

            const SizedBox(height: 20),

            // Journey Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Scheduled Time
                  if (delivery.scheduledPickupTime != null)
                    _buildJourneyStep(
                      icon: Icons.schedule,
                      iconColor: Colors.grey,
                      title: 'Scheduled Pickup',
                      subtitle: DateFormat(
                        'h:mm a',
                      ).format(delivery.scheduledPickupTime!),
                      isCompleted: true,
                    ),

                  // Actual Pickup
                  if (delivery.actualPickupTime != null) ...[
                    const SizedBox(height: 12),
                    _buildJourneyStep(
                      icon: Icons.directions_bus,
                      iconColor: Colors.blue,
                      title: 'Picked Up',
                      subtitle: DateFormat(
                        'h:mm a',
                      ).format(delivery.actualPickupTime!),
                      isCompleted: true,
                    ),
                  ] else if (delivery.status.toLowerCase() == 'picked_up') ...[
                    const SizedBox(height: 12),
                    _buildJourneyStep(
                      icon: Icons.directions_bus,
                      iconColor: Colors.blue,
                      title: 'Picked Up',
                      subtitle: 'In progress',
                      isCompleted: true,
                    ),
                  ],

                  // Actual Dropoff
                  if (delivery.actualDropoffTime != null) ...[
                    const SizedBox(height: 12),
                    _buildJourneyStep(
                      icon: Icons.home,
                      iconColor: Colors.green,
                      title: 'Delivered Home',
                      subtitle: DateFormat(
                        'h:mm a',
                      ).format(delivery.actualDropoffTime!),
                      isCompleted: true,
                    ),
                  ] else if (delivery.status.toLowerCase() == 'delivered') ...[
                    const SizedBox(height: 12),
                    _buildJourneyStep(
                      icon: Icons.home,
                      iconColor: Colors.green,
                      title: 'Delivered Home',
                      subtitle: 'Completed',
                      isCompleted: true,
                    ),
                  ],
                ],
              ),
            ),

            // Performance Indicator
            if (isCompleted &&
                delivery.actualPickupTime != null &&
                delivery.actualDropoffTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Journey completed successfully!',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimelineProgress(Delivery delivery) {
    final steps = ['Scheduled', 'Picked Up', 'Delivered'];
    final currentStep = _getCurrentStep(delivery);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Row(
            children: [
              // Step Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? LinearGradient(
                          colors: [Colors.green, Colors.green.shade600],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                  border: isCurrent
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _getStepIcon(steps[index]),
                  color: Colors.white,
                  size: 16,
                ),
              ),

              // Connecting Line
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green, Colors.green.shade300]
                            : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildJourneyStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted
                ? iconColor.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isCompleted ? iconColor : Colors.grey,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppTheme.textPrimary
                      : Colors.grey.shade600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted
                      ? AppTheme.textSecondary
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted) Icon(Icons.check_circle, color: iconColor, size: 18),
      ],
    );
  }

  int _getCurrentStep(Delivery delivery) {
    switch (delivery.status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'picked_up':
        return 1;
      case 'delivered':
        return 2;
      default:
        return 0;
    }
  }

  IconData _getStepIcon(String step) {
    switch (step) {
      case 'Scheduled':
        return Icons.schedule;
      case 'Picked Up':
        return Icons.directions_bus;
      case 'Delivered':
        return Icons.home;
      default:
        return Icons.circle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'no_show':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'picked_up':
        return Icons.directions_bus;
      case 'delivered':
        return Icons.check_circle;
      case 'no_show':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Scheduled for pickup';
      case 'picked_up':
        return 'On the bus';
      case 'delivered':
        return 'Delivered home safely';
      case 'no_show':
        return 'No show';
      case 'cancelled':
        return 'Trip cancelled';
      default:
        return status;
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Trips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedStatus = 'All';
                        _selectedDateRange = 'All Time';
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Filter
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusOptions.map((status) {
                  final isSelected = _selectedStatus == status;
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedStatus = selected ? status : 'All';
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Date Range Filter
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dateRangeOptions.map((range) {
                  final isSelected = _selectedDateRange == range;
                  return FilterChip(
                    label: Text(range),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedDateRange = selected ? range : 'All Time';
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() async {
    // Reload data with new filters applied on the backend
    await _loadPassengerDeliveries();
  }
}
