import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../logic/bloc/guardian_trip_list_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/widgets/trip_card.dart';
import '../../../../core/services/guardian_service.dart';
import 'guardian_tracking_screen.dart';
import 'guardian_completed_trip_screen.dart';

class GuardianTripListScreen extends StatefulWidget {
  final Passenger? selectedPassenger;

  const GuardianTripListScreen({super.key, this.selectedPassenger});

  @override
  State<GuardianTripListScreen> createState() => _GuardianTripListScreenState();
}

class _GuardianTripListScreenState extends State<GuardianTripListScreen> {
  final ScrollController _scrollController = ScrollController();
  final GuardianService _guardianService = GuardianService();

  List<Passenger> _children = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrips();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _children = []);
    try {
      final children = await _guardianService.getMyPassengers();
      if (mounted) {
        setState(() => _children = children);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _children = []);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadTrips() {
    context.read<GuardianTripListBloc>().loadGuardianTrips(
      passengerId: widget.selectedPassenger?.id,
    );
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<GuardianTripListBloc>().state;
      if (state.isSuccess && state.data != null && !state.data!.hasReachedMax) {
        context.read<GuardianTripListBloc>().loadMoreGuardianTrips(
          page: state.data!.currentPage + 1,
          perPage: 20,
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardHeader(
              title: 'My Trips',
              showBackButton: true,

              subtitle: widget.selectedPassenger != null
                  ? '${widget.selectedPassenger!.displayName}\'s Trips'
                  : 'All Trips',
              actions: [
                HeaderAction(
                  icon: Icons.filter_list,
                  onPressed: _showFilterDialog,
                ),
                HeaderAction(
                  icon: Icons.refresh,
                  onPressed: () {
                    context.read<GuardianTripListBloc>().refreshGuardianTrips(
                      passengerId: widget.selectedPassenger?.id,
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: BlocBuilder<GuardianTripListBloc, BlocState<dynamic>>(
                builder: (context, state) {
                  if (state.isInitial || state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.isError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading trips',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.errorMessage ?? 'Unknown error occurred',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<GuardianTripListBloc>()
                                  .refreshGuardianTrips(
                                    passengerId: widget.selectedPassenger?.id,
                                  );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.isSuccess && state.data != null) {
                    if (state.data!.trips.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_bus,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('No trips found'),
                            const SizedBox(height: 8),
                            Text(
                              'Trips will appear here once scheduled',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context
                            .read<GuardianTripListBloc>()
                            .refreshGuardianTrips(
                              passengerId: widget.selectedPassenger?.id,
                            );
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.data!.hasReachedMax
                            ? state.data!.trips.length
                            : state.data!.trips.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= state.data!.trips.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final trip = state.data!.trips[index];
                          // Debug: Print trip status to see what we're getting
                          print('Trip ${trip.id} status: ${trip.status}');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: UnifiedTripCard(
                              trip: trip,
                              mode: TripCardMode.guardian,
                              onTap: () => _navigateToTracking(trip),
                              onDetails: () => _navigateToTracking(trip),
                              onLiveTracking: () => _navigateToTracking(trip),
                              onPrimaryAction: () => _navigateToTracking(trip),
                              onSecondaryAction: () => _navigateToTracking(trip),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTracking(Trip trip) {
    // Find the passenger for this trip (if selectedPassenger is provided, use it)
    Passenger? passenger = widget.selectedPassenger;

    // If no specific passenger selected, try to find one from the trip
    if (passenger == null &&
        trip.deliveries != null &&
        trip.deliveries!.isNotEmpty) {
      // For now, just use the first delivery's passenger info
      final delivery = trip.deliveries!.first;
      // Create a basic passenger object from delivery info
      passenger = Passenger(
        id: delivery.passengerId,
        firstName: delivery.passengerName?.split(' ').first ?? 'Unknown',
        lastName: delivery.passengerName?.split(' ').skip(1).join(' ') ?? '',
        fullName: delivery.passengerName,
        isActive: true,
        pickupLocation: PassengerLocation(
          address: 'Pickup Address', // Not available in delivery
          coordinates: delivery.pickupLat != null && delivery.pickupLng != null
              ? {
                  'latitude': delivery.pickupLat!,
                  'longitude': delivery.pickupLng!,
                }
              : null,
        ),
        dropoffLocation: PassengerLocation(
          address: 'Dropoff Address', // Not available in delivery
          coordinates:
              delivery.dropoffLat != null && delivery.dropoffLng != null
              ? {
                  'latitude': delivery.dropoffLat!,
                  'longitude': delivery.dropoffLng!,
                }
              : null,
        ),
        schoolClass: PassengerSchoolClass(
          id: 'unknown',
          name: delivery.schoolClass ?? 'Unknown Class',
        ),
      );
    }

    if (passenger != null) {
      // Navigate to appropriate screen based on trip status
      Widget screen;
      if (trip.status == 'completed') {
        screen = GuardianCompletedTripScreen(trip: trip, passenger: passenger);
      } else {
        screen = GuardianTrackingScreen(
          trip: trip,
          focusPassenger: passenger,
          allPassengers: [passenger],
        );
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    }
  }

  void _showFilterDialog() {
    final state = context.read<GuardianTripListBloc>().state;
    if (!state.isSuccess || state.data == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GuardianTripFilterSheet(
        currentFilters: state.data!.filters,
        children: _children,
        onFiltersChanged: (filters) {
          context.read<GuardianTripListBloc>().updateFilters(
            status: filters.status,
            date: filters.date,
            passengerId: filters.passengerId,
          );
          Navigator.pop(context);
        },
      ),
    );
  }
}

class GuardianTripFilterSheet extends StatefulWidget {
  final TripFilters? currentFilters;
  final List<Passenger> children;
  final Function(TripFilters) onFiltersChanged;

  const GuardianTripFilterSheet({
    super.key,
    this.currentFilters,
    required this.children,
    required this.onFiltersChanged,
  });

  @override
  State<GuardianTripFilterSheet> createState() =>
      _GuardianTripFilterSheetState();
}

class _GuardianTripFilterSheetState extends State<GuardianTripFilterSheet> {
  String? _selectedStatus;
  String? _selectedPassengerId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters?.status;
    _selectedPassengerId = widget.currentFilters?.passengerId;
    // Parse date string back to DateTime if available
    if (widget.currentFilters?.date != null) {
      try {
        _selectedDate = DateTime.parse(widget.currentFilters!.date!);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Trips',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Passenger Filter
          if (widget.children.isNotEmpty) ...[
            const Text(
              'Passenger',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Children'),
                  selected: _selectedPassengerId == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPassengerId = null);
                    }
                  },
                ),
                ...widget.children.map(
                  (child) => FilterChip(
                    label: Text(child.displayName),
                    selected: _selectedPassengerId == child.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPassengerId = selected ? child.id : null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Status Filter
          const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedStatus == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = null);
                  }
                },
              ),
              FilterChip(
                label: const Text('Scheduled'),
                selected: _selectedStatus == 'scheduled',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = 'scheduled');
                  }
                },
              ),
              FilterChip(
                label: const Text('In Progress'),
                selected: _selectedStatus == 'in_progress',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = 'in_progress');
                  }
                },
              ),
              FilterChip(
                label: const Text('Completed'),
                selected: _selectedStatus == 'completed',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedStatus = 'completed');
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date Filter
          const Text('Date', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                      : 'All dates',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Text(_selectedDate != null ? 'Change' : 'Select Date'),
              ),
              if (_selectedDate != null)
                TextButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  child: const Text('Clear'),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(
                  TripFilters(
                    status: _selectedStatus,
                    date: _selectedDate?.toIso8601String().split('T').first,
                    passengerId: _selectedPassengerId,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
