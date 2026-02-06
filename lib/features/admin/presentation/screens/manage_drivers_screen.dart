import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/driver.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../widgets/driver_form_sheet.dart';
import 'driver_detail_screen.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadDrivers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDriverDialog(BuildContext context, {Driver? driver}) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DriverFormSheet(driver: driver),
    );

    if (result != null && mounted) {
      if (driver == null) {
        bloc.add(AdminCreateDriver(result));
      } else {
        bloc.add(AdminUpdateDriver(driver.id, result));
      }
    }
  }

  void _confirmDelete(BuildContext context, Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.fullName}?'),
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
              context.read<AdminBloc>().add(AdminDeleteDriver(driver.id));
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
            return current is AdminDriversLoaded || current is AdminLoading;
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const AdminLoadDrivers());
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      title: 'Manage Drivers',
                      subtitle: 'Register and monitor your driving staff',
                      showBackButton:true,
                      actions: [
                        HeaderAction(
                          icon: Icons.person_add_outlined,
                          onPressed: () => _showDriverDialog(context),
                        ),
                      ],
                    ),
                  ),

                  // Search and Filters
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          AppTextField(
                            label: '',
                            controller: _searchController,
                            hint: 'Search drivers by name or email...',
                            prefixIcon: const Icon(Icons.search),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          FilterChipGroup(
                            filters: const ['All', 'Active', 'Inactive'],
                            initialValue: _selectedFilter,
                            onSelected: (filter) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Drivers List
                  if (state is AdminLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is AdminDriversLoaded)
                    _buildDriversList(state.drivers)
                  else
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriversList(List<Driver> drivers) {
    final filteredDrivers = drivers.where((driver) {
      final matchesSearch = driver.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          driver.email.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (driver.isActive && _selectedFilter == 'Active') ||
          (!driver.isActive && _selectedFilter == 'Inactive');

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredDrivers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No drivers found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final driver = filteredDrivers[index];
            return _buildDriverCard(driver);
          },
          childCount: filteredDrivers.length,
        ),
      ),
    );
  }

  Widget _buildDriverCard(Driver driver) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverDetailScreen(driver: driver),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: driver.avatar != null
                    ? NetworkImage(driver.avatar!)
                    : null,
                child: driver.avatar == null
                    ? Text(
                        driver.fullName.isNotEmpty ? driver.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        driver.isActive
                            ?  AppBadge.success(label: 'Active')
                            :  AppBadge.error(label: 'Inactive'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            driver.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'License: ${driver.licenseNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (driver.phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            driver.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (driver.currentRoute != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.route_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Route: ${driver.currentRoute!.name}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showDriverDialog(context, driver: driver),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, driver),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
