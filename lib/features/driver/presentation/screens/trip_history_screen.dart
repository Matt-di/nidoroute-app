import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import 'package:nitoroute/core/bloc/trip_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/widgets/simple_trip_card.dart';
import '../../../../core/widgets/filter_bottom_sheet.dart';
import 'live_tracking_screen.dart';
import 'trip_detail_screen.dart';
import 'driver_completed_trip_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  TripFilter? _selectedFilter;
  TripSort? _selectedSort;
  DateTime? _selectedDate;
  String? _searchQuery;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-load trips on first visit - wait for user interaction
    _scrollController.addListener(_onScroll);
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
    // Only reload data if there are active filters or if data is completely missing
    final tripState = context.read<TripBloc>().state;
    final hasActiveFilters = _selectedFilter != null || 
                           _selectedDate != null || 
                           (_searchQuery?.isNotEmpty ?? false);
    
    if (hasActiveFilters && (tripState.isInitial || tripState.isError)) {
      _loadInitialTrips();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialTrips() async {
    context.read<TripBloc>().add(
      TripListLoadRequested(
        type: TripListType.history,
        filters: TripFilters(
          date: _selectedDate?.toIso8601String().split('T').first,
          status: _selectedFilter != null ? _getFilterStatusString(_selectedFilter!) : null,
        ),
        page: 1,
        perPage: 20,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      _loadMoreTrips();
    }
  }

  void _loadMoreTrips() {
    final state = context.read<TripBloc>().state;
    if (state.isSuccess && state.data != null) {
      final tripListData = state.data as TripListData;
      if (!tripListData.hasReachedMax && !_isLoadingMore) {
        setState(() => _isLoadingMore = true);
        context.read<TripBloc>().add(
          TripListLoadMoreRequested(
            filters: TripFilters(
              date: _selectedDate?.toIso8601String().split('T').first,
              status: _selectedFilter != null ? _getFilterStatusString(_selectedFilter!) : null,
            ),
            page: tripListData.currentPage + 1,
            perPage: 20,
          ),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(
      context: context,
      selectedFilter: _selectedFilter,
      selectedSort: _selectedSort,
      selectedDate: _selectedDate,
      searchQuery: _searchQuery,
      onFiltersChanged: (filter, sort, date, query) {
        setState(() {
          _selectedFilter = filter;
          _selectedSort = sort;
          _selectedDate = date;
          _searchQuery = query;
        });
        _loadInitialTrips();
      },
      onClearAll: () {
        setState(() {
          _selectedFilter = null;
          _selectedDate = null;
          _searchQuery = null;
          _selectedSort = TripSort.date;
        });
        _loadInitialTrips();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildModernHeader(),
          Expanded(child: _buildTripList()),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20 + MediaQuery.of(context).padding.top, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor.withOpacity(0.6),
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
                      child: const Text(
                        'Trip History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'My Trips',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_hasActiveFilters())
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = null;
                        _selectedDate = null;
                        _searchQuery = null;
                        _selectedSort = TripSort.date;
                      });
                      _loadInitialTrips();
                    },
                    child: const Icon(
                      Icons.clear_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedFilter != null || 
           _selectedDate != null || 
           (_searchQuery?.isNotEmpty ?? false) ||
           _selectedSort != TripSort.date;
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    if (_selectedFilter != null) filters.add(_selectedFilter!.name);
    if (_selectedDate != null) {
      filters.add(DateFormat('MMM d').format(_selectedDate!));
    }
    if (_searchQuery?.isNotEmpty ?? false) filters.add('Search: $_searchQuery');
    if (_selectedSort != TripSort.date) filters.add('Sorted');
    return filters.join(' • ');
  }

  Widget _buildTripList() {
    return BlocConsumer<TripBloc, BlocState<dynamic>>(
      listener: (context, state) {
        if (state.isSuccess && state.data != null) {
          final tripListData = state.data as TripListData;
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isSuccess && state.data != null) {
          final tripListData = state.data as TripListData;
          final List<Trip> trips = tripListData.trips;

          final bool hasMorePages = !tripListData.hasReachedMax;

          if (trips.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No trips found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateMessage(state),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_hasActiveFilters()) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = null;
                            _selectedDate = null;
                            _searchQuery = null;
                            _selectedSort = TripSort.date;
                          });
                          _loadInitialTrips();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear_all_rounded,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Clear filters',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (state.isInitial) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: _loadInitialTrips,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Load Trip History',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadInitialTrips(),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(AppTheme.spacing16),
              itemCount: trips.length + (hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == trips.length) {
                  return _buildLoadingIndicator();
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: AppTheme.spacing16),
                  child: SimpleTripCard(
                    trip: trips[index],
                    mode: SimpleTripCardMode.driver,
                    onTap: () => _onTripTapped(trips[index]),
                    onPrimaryAction: () => _onTripTapped(trips[index]),
                  ),
                );
              },
            ),
          );
        }

        if (state.isError) {
          return Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading trip history',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Unknown error occurred',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadInitialTrips(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Default return
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _getEmptyStateMessage(BlocState state) {
    if (_hasActiveFilters()) {
      return 'No trips match your current filters. Try adjusting your search criteria.';
    }
    
    if (state.isInitial) {
      return 'Tap the button below to load your trip history.';
    }
    
    return 'You haven\'t completed any trips yet. Your trip history will appear here.';
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  void _onTripTapped(Trip trip) {
    if (trip.status == 'in_progress' || trip.status == 'active') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LiveTrackingScreen(trip: trip)),
      );
    } else if (trip.status == 'completed') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DriverCompletedTripScreen(trip: trip)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
      );
    }
  }

  void _onRemindMe(Trip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${trip.route?.name ?? 'trip'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _getFilterStatusString(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return null; // No status filter for "all"
      case TripFilter.completed:
        return 'completed';
      case TripFilter.inProgress:
        return 'in_progress';
      case TripFilter.upcoming:
        return 'scheduled';
    }
  }
}
