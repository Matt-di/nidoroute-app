import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../widgets/trip_form_sheet.dart';
import '../widgets/trip_filter_modal.dart';
import '../widgets/trip_list_tab.dart';
import '../widgets/trip_map_tab.dart';
import '../widgets/trip_history_tab.dart';

class TripMonitoringScreen extends StatefulWidget {
  const TripMonitoringScreen({super.key});

  @override
  State<TripMonitoringScreen> createState() => _TripMonitoringScreenState();
}

class _TripMonitoringScreenState extends State<TripMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasLoadedInitialData = false;

  // Filter states
  String _selectedStatus = 'All';
  String _selectedDateRange = 'All Time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadTripsForCurrentTab();
      }
    });
    
    // Load data after the first frame to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoadedInitialData) {
        _loadInitialData();
        _hasLoadedInitialData = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Additional safety check to load data if it hasn't been loaded yet
    if (!_hasLoadedInitialData) {
      Future.microtask(() {
        if (mounted && !_hasLoadedInitialData) {
          _loadInitialData();
          _hasLoadedInitialData = true;
        }
      });
    }
  }

  void _loadInitialData() {
    // Load both active trips and all trips for comprehensive data
    context.read<AdminBloc>().add(const AdminLoadActiveTrips());
    context.read<AdminBloc>().add(const AdminLoadAllTrips());
  }

  void _loadTripsForCurrentTab() {
    switch (_tabController.index) {
      case 0: // List tab
      case 1: // Map tab
        context.read<AdminBloc>().add(const AdminLoadActiveTrips());
        break;
      case 2: // History tab
        context.read<AdminBloc>().add(const AdminLoadAllTrips());
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showScheduleDialog(BuildContext context) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BlocProvider.value(value: bloc, child: const TripFormSheet()),
    );

    if (result != null && mounted) {
      bloc.add(AdminCreateTrip(result));
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius24)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => TripFilterModal(
        selectedStatus: _selectedStatus,
        selectedDateRange: _selectedDateRange,
        onStatusChanged: (status) => setState(() => _selectedStatus = status),
        onDateRangeChanged: (range) =>
            setState(() => _selectedDateRange = range),
        onApplyFilters: _applyFilters,
        onClearAll: _clearFilters,
      ),
    );
  }

  void _applyFilters() {
    _loadTripsForCurrentTab();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'All';
      _selectedDateRange = 'All Time';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DashboardHeader(
      title: 'Trip Monitoring',
      subtitle: 'Track active routes and manage schedules',
      actions: [
        HeaderAction(
          icon: Icons.filter_list,
          onPressed: _showFilterModal,
        ),
        HeaderAction(
          icon: Icons.calendar_today_rounded,
          onPressed: () => _showScheduleDialog(context),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt_outlined, size: 20),
            text: 'List',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.map_outlined, size: 20),
            text: 'Map',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.history_outlined, size: 20),
            text: 'History',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadTripsForCurrentTab(),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return TabBarView(
          controller: _tabController,
          children: const [
            TripListTab(),
            TripMapTab(),
            TripHistoryTab(),
          ],
        );
      },
    );
  }
}
