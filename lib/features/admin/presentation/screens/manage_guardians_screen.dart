import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/bloc/admin_bloc.dart';
import '../../logic/bloc/admin_event.dart';
import '../../logic/bloc/admin_state.dart';
import '../../../../core/models/guardian.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/filter_chip_group.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_badge.dart';
import '../widgets/guardian_form_sheet.dart';

class ManageGuardiansScreen extends StatefulWidget {
  const ManageGuardiansScreen({super.key});

  @override
  State<ManageGuardiansScreen> createState() => _ManageGuardiansScreenState();
}

class _ManageGuardiansScreenState extends State<ManageGuardiansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadGuardians());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGuardianDialog(BuildContext context, {Guardian? guardian}) async {
    final bloc = context.read<AdminBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GuardianFormSheet(guardian: guardian),
    );

    if (result != null && mounted) {
      if (guardian == null) {
        bloc.add(AdminCreateGuardian(result));
      } else {
        bloc.add(AdminUpdateGuardian(guardian.id, result));
      }
    }
  }

  void _confirmDelete(BuildContext context, Guardian guardian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guardian'),
        content: Text('Are you sure you want to delete ${guardian.fullName}?'),
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
              context.read<AdminBloc>().add(AdminDeleteGuardian(guardian.id));
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
            return current is AdminGuardiansLoaded || current is AdminLoading;
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(const AdminLoadGuardians());
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      title: 'Manage Guardians',
                      subtitle: 'Register parents and legal guardians',
                      showBackButton:true,
                      actions: [
                        HeaderAction(
                          icon: Icons.group_add_outlined,
                          onPressed: () => _showGuardianDialog(context),
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
                            hint: 'Search guardians by name or email...',
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

                  // Guardians List
                  if (state is AdminLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is AdminGuardiansLoaded)
                    _buildGuardiansList(state.guardians)
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

  Widget _buildGuardiansList(List<Guardian> guardians) {
    final filteredGuardians = guardians.where((guardian) {
      final matchesSearch = guardian.fullName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          guardian.email.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesFilter = _selectedFilter == 'All' ||
          (guardian.isActive && _selectedFilter == 'Active') ||
          (!guardian.isActive && _selectedFilter == 'Inactive');

      return matchesSearch && matchesFilter;
    }).toList();

    if (filteredGuardians.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No guardians found',
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
            final guardian = filteredGuardians[index];
            return _buildGuardianCard(guardian);
          },
          childCount: filteredGuardians.length,
        ),
      ),
    );
  }

  Widget _buildGuardianCard(Guardian guardian) {
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
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: Text(
                guardian.fullName.isNotEmpty ? guardian.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guardian.fullName,
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
                          guardian.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (guardian.phone != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          guardian.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (guardian.passengersCount != null && guardian.passengersCount! > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.child_care, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${guardian.passengersCount} passenger${guardian.passengersCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
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
                  onPressed: () => _showGuardianDialog(context, guardian: guardian),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, guardian),
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
