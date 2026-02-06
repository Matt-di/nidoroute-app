import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../widgets/passenger_form_sheet.dart';

class ManagePassengersScreen extends StatefulWidget {
  const ManagePassengersScreen({super.key});

  @override
  State<ManagePassengersScreen> createState() => _ManagePassengersScreenState();
}

class _ManagePassengersScreenState extends State<ManagePassengersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadPassengers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPassengerDialog(BuildContext context, {Passenger? passenger}) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PassengerFormSheet(passenger: passenger),
    );

    if (result != null && mounted) {
      if (passenger == null) {
        bloc.add(AdminCreatePassenger(result));
      } else {
        bloc.add(AdminUpdatePassenger(passenger.id, result));
      }
    }
  }

  void _confirmDelete(BuildContext context, Passenger passenger) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Passenger'),
        content: Text('Are you sure you want to delete ${passenger.displayName}?'),
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
              context.read<AdminBloc>().add(AdminDeletePassenger(passenger.id));
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
            return current is AdminPassengersLoaded || current is AdminLoading;
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const AdminLoadPassengers());
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      title: 'Manage Passengers',
                      subtitle: 'Manage student records and pickup points',
                      actions: [
                        HeaderAction(
                          icon: Icons.person_add_alt_1_outlined,
                          onPressed: () => _showPassengerDialog(context),
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
                            hint: 'Search passengers by name...',
                            prefixIcon: const Icon(Icons.search),
                            onChanged: (value) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          FilterChipGroup(
                            filters: const ['All', 'Active', 'Inactive', 'Has Guardian', 'No Guardian'],
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

                  // Passengers List
                  if (state is AdminLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is AdminPassengersLoaded)
                    _buildPassengersList(state.passengers)
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

  Widget _buildPassengersList(List<Passenger> passengers) {
    final filteredPassengers = passengers.where((passenger) {
      final matchesSearch = passenger.displayName.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (passenger.isActive && _selectedFilter == 'Active') ||
          (!passenger.isActive && _selectedFilter == 'Inactive') ||
          (passenger.guardian != null && _selectedFilter == 'Has Guardian') ||
          (passenger.guardian == null && _selectedFilter == 'No Guardian');

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredPassengers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No passengers found',
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
            final passenger = filteredPassengers[index];
            return _buildPassengerCard(passenger);
          },
          childCount: filteredPassengers.length,
        ),
      ),
    );
  }

  Widget _buildPassengerCard(Passenger passenger) {
    return Container(
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
            Hero(
              tag: 'passenger_${passenger.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  image: passenger.image != null
                      ? DecorationImage(
                          image: NetworkImage(passenger.image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: passenger.image == null
                    ? Icon(
                        passenger.gender?.toLowerCase() == 'female' 
                            ? Icons.face_3 
                            : Icons.face,
                        color: Colors.grey.shade400,
                        size: 32,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        passenger.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      passenger.isActive
                          ?  AppBadge.success(label: 'Active')
                          :  AppBadge.error(label: 'Inactive'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          passenger.pickupLocation?.address ?? 'No pickup address',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (passenger.schoolClass != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.school_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Class: ${passenger.schoolClass!.name}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (passenger.guardian != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.family_restroom, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Guardian: ${passenger.guardian!.user?.fullName ?? 'Unknown'}',
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
                  onPressed: () => _showPassengerDialog(context, passenger: passenger),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, passenger),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
