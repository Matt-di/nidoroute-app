import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_section_title.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState.isSuccess && authState.data != null) {
      _firstNameController = TextEditingController(
        text: authState.data?.user?.firstName ?? '',
      );
      _lastNameController = TextEditingController(
        text: authState.data?.user?.lastName ?? '',
      );
      _emailController = TextEditingController(
        text: authState.data?.user?.email ?? '',
      );
      _phoneController = TextEditingController(
        text: '',
      ); // TODO: Add phone to user model
    } else {
      _firstNameController = TextEditingController();
      _lastNameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BlocState<AuthData>>(
      builder: (context, authState) {
        if (!authState.isSuccess || authState.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      title: 'Profile',
                      subtitle: 'Manage your account information',

                      actions: [
                        if (_isEditing)
                          HeaderAction(
                            icon: Icons.close,
                            onPressed: _cancelEditing,
                          )
                        else
                          HeaderAction(
                            icon: Icons.edit,
                            onPressed: _startEditing,
                          ),
                      ],
                      showBackButton: true,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildProfileAvatar(authState.data!),
                          const SizedBox(height: 32),
                          _buildProfileForm(authState.data!),
                          if (_isEditing) ...[
                            const SizedBox(height: 32),
                            _buildActionButtons(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(AuthData authData) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(authData.user?.firstName ?? '')[0]}${(authData.user?.lastName ?? '')[0]}'
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(AuthData authData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'PERSONAL INFORMATION',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            enabled: false, // Email should not be editable
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Phone number is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),
          const AppSectionTitle(
            title: 'ACCOUNT DETAILS',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),

          _buildInfoRow('Role', _getRoleDisplayName(authData.role ?? '')),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Member Since',
            _formatJoinDate(null),
          ), // TODO: Add createdAt to User model
          const SizedBox(height: 16),
          _buildInfoRow('Account Status', 'Active'),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      enabled: enabled,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Cancel',
            variant: AppButtonVariant.outlined,
            onPressed: _isLoading ? null : _cancelEditing,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppButton(
            text: 'Save Changes',
            onPressed: _isLoading ? null : _saveProfile,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isSuccess && authState.data != null) {
      // Reset form to original values
      _firstNameController.text = authState.data?.user!.firstName ?? '';
      _lastNameController.text = authState.data?.user!.lastName ?? '';
      _emailController.text = authState.data?.user!.email ?? '';
      _phoneController.text = ''; // TODO: Reset phone
    }

    setState(() {
      _isEditing = false;
    });
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement profile update API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return 'Bus Driver';
      case 'guardian':
        return 'Parent/Guardian';
      case 'admin':
        return 'Administrator';
      default:
        return role;
    }
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
