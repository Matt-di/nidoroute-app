import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/route.dart' as model;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/services/route_service.dart';
import '../../../../core/services/trip_service.dart';
import '../../../route/logic/bloc/route_bloc.dart';
import '../../../route/logic/bloc/route_event.dart';
import '../../../route/logic/bloc/route_state.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;

  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RouteBloc(
        routeService: context.read<RouteService>(),
        tripService: context.read<TripService>(),
      )..add(RouteDetailLoadRequested(routeId)),
      child: const _RouteDetailScreenView(),
    );
  }
}

class _RouteDetailScreenView extends StatelessWidget {
  const _RouteDetailScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        if (state is RouteLoading) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (state is RouteError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading route details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // For simplicity, we'll just show a generic retry
                        // In a real app, you'd want to store the routeId in the BLoC
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please go back and try again'),
                          ),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is RouteLoaded) {
          return _RouteDetailContent(route: state.route);
        }

        if (state is RouteWithTripsLoaded) {
          return _RouteDetailContent(route: state.route, trips: state.trips, filters: state.filters);
        }

        if (state is RouteTripsLoading) {
          return _RouteDetailContent(route: state.route, isLoadingTrips: true);
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: const SafeArea(child: Center(child: Text('Route not found'))),
        );
      },
    );
  }
}

class _RouteDetailContent extends StatelessWidget {
  final model.Route route;
  final List<dynamic>? trips;
  final Map<String, dynamic>? filters;
  final bool isLoadingTrips;

  const _RouteDetailContent({
    required this.route,
    this.trips,
    this.filters,
    this.isLoadingTrips = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: DashboardHeader(
                title: 'Route Details',
                subtitle: route.name,
                actions: [
                  HeaderAction(
                    icon: Icons.refresh,
                    onPressed: () {
                      context.read<RouteBloc>().add(
                        RouteDetailLoadRequested(route.id),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Route Status & Basic Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteHeader(route),
                    const SizedBox(height: 24),
                    _buildRouteMetrics(route),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Detailed Information Sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRouteInfo(route),
                    const SizedBox(height: 24),
                    _buildDriverInfo(route),
                    const SizedBox(height: 24),
                    _buildCarInfo(route),
                    const SizedBox(height: 24),
                    _buildPassengersList(route),
                    const SizedBox(height: 24),
                    _buildRouteStops(route),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRouteHeader(model.Route route) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alt_route,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Route ID: ${route.id.substring(0, 8)}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            route.createdAt?.toString().split(' ')[0] ?? 'N/A',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMetrics(model.Route route) {
    final passengerCount = route.stops?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Passengers',
            value: '$passengerCount',
            icon: Icons.people,
            isDark: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Duration',
            value: '${route.estimatedDuration ?? 0} min',
            icon: Icons.schedule,
            isDark: false,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(model.Route route) {
    return _buildInfoSection('Route Information', Icons.route, [
      _buildInfoRow('Route Name', route.name),
      _buildInfoRow('Description', route.description ?? 'No description'),
      _buildInfoRow('Start Address', route.startAddress ?? 'Not set'),
      _buildInfoRow('End Address', route.endAddress ?? 'Not set'),
      _buildInfoRow(
        'Estimated Duration',
        '${route.estimatedDuration ?? 0} minutes',
      ),
    ]);
  }

  Widget _buildDriverInfo(model.Route route) {
    final driver = route.driver;
    if (driver == null) {
      return _buildInfoSection('Driver Information', Icons.person, [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No driver assigned',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ]);
    }

    return _buildInfoSection('Driver Information', Icons.person, [
      _buildInfoRow('Name', driver.user?.name ?? 'Unknown'),
      _buildInfoRow('Driver ID', driver.id.substring(0, 8)),
    ]);
  }

  Widget _buildCarInfo(model.Route route) {
    final car = route.car;
    if (car == null) {
      return _buildInfoSection('Vehicle Information', Icons.directions_car, [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No vehicle assigned',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ]);
    }

    return _buildInfoSection('Vehicle Information', Icons.directions_car, [
      _buildInfoRow('Model', car.model),
      _buildInfoRow('Plate Number', car.plateNumber),
      _buildInfoRow('Car ID', car.id.substring(0, 8)),
    ]);
  }

  Widget _buildPassengersList(model.Route route) {
    final stops = route.stops;
    if (stops == null || stops.isEmpty) {
      return _buildInfoSection('Passengers', Icons.people, [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No passengers assigned to this route',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      ]);
    }

    return _buildInfoSection('Passengers (${stops.length})', Icons.people, [
      ...stops.map(
        (stop) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStopStatusColor(
                    stop.status,
                  ).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStopStatusIcon(stop.status),
                  color: _getStopStatusColor(stop.status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              // Passenger info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.passenger?.name ?? 'Unknown Passenger',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stop ID: ${stop.id.substring(0, 8)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Status text and coordinates
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStopStatusColor(
                        stop.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStopStatusText(stop.status),
                      style: TextStyle(
                        color: _getStopStatusColor(stop.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildRouteStops(model.Route route) {
    final stops = route.stops;
    if (stops == null || stops.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildInfoSection('Route Stops Overview', Icons.location_on, [
      _buildInfoRow('Total Stops', '${stops.length}'),
      if (route.startAddress != null)
        _buildInfoRow('Start Point', route.startAddress!),
      _buildInfoRow(
        'Start Coords',
        route.startLat != null && route.startLng != null
            ? '${route.startLat!.toStringAsFixed(4)}, ${route.startLng!.toStringAsFixed(4)}'
            : 'Not set',
      ),
      if (route.endAddress != null)
        _buildInfoRow('End Point', route.endAddress!),
      _buildInfoRow(
        'End Coords',
        route.endLat != null && route.endLng != null
            ? '${route.endLat!.toStringAsFixed(4)}, ${route.endLng!.toStringAsFixed(4)}'
            : 'Not set',
      ),
    ]);
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'in_progress':
        return Icons.directions_bus;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStopStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStopStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'skipped':
        return Icons.skip_next;
      default:
        return Icons.help;
    }
  }

  String _getStopStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'skipped':
        return 'Skipped';
      default:
        return 'Unknown';
    }
  }
}
