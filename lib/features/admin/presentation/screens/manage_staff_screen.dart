import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../widgets/staff_form_sheet.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadStaff());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStaffDialog(BuildContext context, {User? staff}) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StaffFormSheet(staff: staff),
    );

    if (result != null && mounted) {
      if (staff == null) {
        bloc.add(AdminCreateStaff(result));
      } else {
        bloc.add(AdminUpdateStaff(staff.id, result));
      }
    }
  }

  void _confirmDelete(BuildContext context, User staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.fullName}?'),
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
              context.read<AdminBloc>().add(AdminDeleteStaff(staff.id));
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
          buildWhen: (previous, current) => current is AdminStaffLoaded || current is AdminLoading,
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const AdminLoadStaff());
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      title: 'Manage Staff',
                      subtitle: 'Administrators and office personnel',
                      showBackButton:true,

                      actions: [
                        HeaderAction(
                          icon: Icons.person_add_outlined,
                          onPressed: () => _showStaffDialog(context),
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
                            hint: 'Search staff by name...',
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

                  // Staff List
                  if (state is AdminLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is AdminStaffLoaded)
                    _buildStaffList(state.staff)
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

  Widget _buildStaffList(List<User> staffList) {
    final filteredStaff = staffList.where((staff) {
      final matchesSearch = staff.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          staff.email.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || 
          (_selectedFilter == 'Active') || 
          (_selectedFilter == 'Inactive' && false);

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredStaff.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No staff members found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
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
            final staff = filteredStaff[index];
            return _buildStaffCard(staff);
          },
          childCount: filteredStaff.length,
        ),
      ),
    );
  }

  Widget _buildStaffCard(User staff) {
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
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: Text(
                staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          staff.email,
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
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showStaffDialog(context, staff: staff),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, staff),
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

