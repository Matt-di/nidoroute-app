import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/route.dart' as model;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../widgets/route_form_sheet.dart';
import 'route_detail_screen.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Routes';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadRoutes());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRouteDialog(BuildContext context, {model.Route? route}) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteFormSheet(route: route),
    );

    if (result != null && mounted) {
      if (route == null) {
        bloc.add(AdminCreateRoute(result));
      } else {
        bloc.add(AdminUpdateRoute(route.id, result));
      }
    }
  }

  void _confirmDelete(BuildContext context, model.Route route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete ${route.name}?'),
        actions: [
          AppButton(
            text: 'Cancel',
            variant: AppButtonVariant.text,
            isFullWidth: false,
            onPressed: () => Navigator.pop(context),
          ),
          AppButton(
            text: 'Delete',
            variant: AppButtonVariant.text,
            isFullWidth: false,
            textColor: Colors.red,
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminBloc>().add(AdminDeleteRoute(route.id));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            DashboardHeader(
              title: 'Route Management',
              subtitle: 'ADMIN',
              showBackButton: true,
              actions: [
                HeaderAction(
                  icon: Icons.account_circle_outlined,
                  onPressed: () {},
                ),
              ],
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppTextField(
                label: '',
                controller: _searchController,
                hint: 'Search routes or drivers...',
                prefixIcon: const Icon(Icons.search),
                onChanged: (value) => setState(() {}),
              ),
            ),

            // Filters
            FilterChipGroup(
              filters: const ['All Routes', 'Driver'],
              initialValue: _selectedFilter,
              onSelected: (value) => setState(() => _selectedFilter = value),
            ),

            // Routes List
            Expanded(
              child: BlocConsumer<AdminBloc, AdminState>(
                listener: (context, state) {
                  if (state is AdminOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                    );
                  } else if (state is AdminError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                },
                buildWhen: (previous, current) {
                  // Only rebuild when routes are loaded or when we're loading routes specifically
                  return current is AdminRoutesLoaded || 
                         (current is AdminLoading && previous is! AdminRoutesLoaded);
                },
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AdminRoutesLoaded) {
                    final filteredRoutes = state.routes.where((r) {
                      final query = _searchController.text.toLowerCase();
                      final matchesQuery = r.name.toLowerCase().contains(query) ||
                          (r.driver?.user?.name.toLowerCase().contains(query) ?? false);

                      if (_selectedFilter == 'Driver') return matchesQuery && r.driver != null;
                      return matchesQuery;
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<AdminBloc>().add(const AdminLoadRoutes());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        itemCount: filteredRoutes.length,
                        itemBuilder: (context, index) => _buildRouteCard(context, filteredRoutes[index]),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'manage_routes_fab',
        onPressed: () => _showRouteDialog(context),
        backgroundColor: const Color(0xFF0D1EFF), // Matching design FAB color
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, model.Route route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteDetailScreen(routeId: route.id),
              ),
            );
          },
          onLongPress: () => _showRouteActions(context, route),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.map_rounded, color: Color(0xFF3F51B5)),
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
                          const SizedBox(height: 4),
                                Text(
                                  route.driver?.user?.name ?? 'Unassigned',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    AppBadge.info(label: '${route.stops?.length ?? 0} STOPS'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.startAddress ?? 
                                (route.startLat != null && route.startLng != null
                                    ? '${route.startLat!.toStringAsFixed(4)}, ${route.startLng!.toStringAsFixed(4)}'
                                    : 'Not set'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0D1EFF)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            route.endAddress ?? 
                                (route.endLat != null && route.endLng != null
                                    ? '${route.endLat!.toStringAsFixed(4)}, ${route.endLng!.toStringAsFixed(4)}'
                                    : 'Not set'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRouteActions(BuildContext context, model.Route route) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailScreen(routeId: route.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Route'),
              onTap: () {
                Navigator.pop(context);
                _showRouteDialog(context, route: route);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Route'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
