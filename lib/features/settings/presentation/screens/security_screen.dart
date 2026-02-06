import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../auth/logic/bloc/auth_event.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, BlocState<AuthData>>(
      listener: (context, state) {
        if (state.isError && state.errorMessage?.contains('password') == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.isSuccess && state.errorMessage?.contains('password') == false) {
          // Check if this was a password change success
          // We'll need to track this differently or add a success message to the state
        }
      },
      builder: (context, authState) {
        if (!authState.isSuccess || authState.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeader(
                    title: 'Security',
                    subtitle: 'Manage your account security',
                    actions: const [],
                    showBackButton: true,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Change Password'),
                        const SizedBox(height: 16),
                        _buildPasswordChangeForm(),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Security Settings'),
                        const SizedBox(height: 16),
                        _buildSecuritySettings(),

                        const SizedBox(height: 32),
                        _buildSectionTitle('Account Security'),
                        const SizedBox(height: 16),
                        _buildAccountSecurity(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildPasswordChangeForm() {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _currentPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              obscureText: _obscureCurrentPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: 'Enter your new password',
              obscureText: _obscureNewPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                  return 'Password must contain uppercase, lowercase, and number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Confirm your new password',
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            AppButton(
              text: 'Change Password',
              onPressed: _isLoading ? null : _changePassword,
              isLoading: _isLoading,
              width: double.infinity,
            ),

            const SizedBox(height: 16),

            Text(
              'Password Requirements:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
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
      child: Column(
        children: [
          _buildSecurityTile(
            icon: Icons.fingerprint,
            title: 'Biometric Authentication',
            subtitle: 'Use fingerprint or face unlock',
            trailing: Switch(
              value: false, // TODO: Implement biometric settings
              onChanged: (value) {
                // TODO: Implement biometric toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric authentication coming soon')),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildSecurityTile(
            icon: Icons.smartphone,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            trailing: Switch(
              value: false, // TODO: Implement 2FA settings
              onChanged: (value) {
                // TODO: Implement 2FA toggle
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Two-factor authentication coming soon')),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildSecurityTile(
            icon: Icons.devices,
            title: 'Active Sessions',
            subtitle: 'Manage your active login sessions',
            onTap: () {
              // TODO: Navigate to active sessions screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Active sessions management coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurity() {
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
      child: Column(
        children: [
          _buildSecurityTile(
            icon: Icons.history,
            title: 'Login History',
            subtitle: 'View your recent login activity',
            onTap: () {
              // TODO: Navigate to login history screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Login history coming soon')),
              );
            },
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildSecurityTile(
            icon: Icons.warning,
            title: 'Security Alerts',
            subtitle: 'Manage security notifications',
            onTap: () {
              // TODO: Navigate to security alerts screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security alerts coming soon')),
              );
            },
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildSecurityTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Settings',
            subtitle: 'Control your data and privacy',
            onTap: () {
              // TODO: Navigate to privacy settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use AuthBloc to change password
      context.read<AuthBloc>().add(
        AuthPasswordChanged(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        ),
      );

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
