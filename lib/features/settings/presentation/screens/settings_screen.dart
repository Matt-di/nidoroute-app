import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../auth/logic/bloc/auth_event.dart';
import '../../../../core/bloc/base_state.dart';
import '../../logic/bloc/settings_bloc.dart';
import '../../logic/bloc/settings_event.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import 'profile_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BlocState<AuthData>>(
      builder: (context, authState) {
        if (!authState.isSuccess || authState.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocBuilder<SettingsBloc, BlocState<AppSettings>>(
          builder: (context, settingsState) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: DashboardHeader(
                        title: 'Settings',
                        subtitle: 'Manage your preferences',
                        actions: const [],
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Account'),
                            const SizedBox(height: 16),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.person_outline,
                                title: 'Profile Information',
                                subtitle: 'Update your personal details',
                                onTap: () => _navigateToProfile(context),
                              ),
                              _buildSettingsTile(
                                icon: Icons.security,
                                title: 'Security',
                                subtitle: 'Change password & security settings',
                                onTap: () => _navigateToSecurity(context),
                              ),
                            ]),

                            const SizedBox(height: 32),
                            _buildSectionTitle('Notifications'),
                            const SizedBox(height: 16),
                            _buildSettingsCard([
                              _buildSwitchTile(
                                icon: Icons.notifications_outlined,
                                title: 'Push Notifications',
                                subtitle: 'Receive trip updates & alerts',
                                value: settingsState.isSuccess
                                    ? settingsState.data?.pushNotifications ?? true
                                    : true,
                                onChanged: (value) {
                                  context.read<SettingsBloc>().add(
                                    SettingsPushNotificationsChanged(value),
                                  );
                                                                },
                              ),
                              _buildSwitchTile(
                                icon: Icons.sms_outlined,
                                title: 'SMS Notifications',
                                subtitle: 'Receive important updates via SMS',
                                value: settingsState.isSuccess
                                    ? settingsState.data?.smsNotifications ?? false
                                    : false,
                                onChanged: (value) {
                                  context.read<SettingsBloc>().add(
                                    SettingsSmsNotificationsChanged(value),
                                  );
                                                                },
                              ),
                            ]),

                            const SizedBox(height: 32),
                            _buildSectionTitle('Support'),
                            const SizedBox(height: 16),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About',
                                subtitle: 'App version & information',
                                trailing: const Text(
                                  'v1.0.0',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                onTap: () => _showAboutDialog(context),
                              ),
                            ]),

                            const SizedBox(height: 32),
                            _buildSettingsCard([
                              _buildSettingsTile(
                                icon: Icons.logout,
                                title: 'Sign Out',
                                subtitle: 'Sign out of your account',
                                textColor: Colors.red,
                                onTap: () => _showSignOutBottomSheet(context),
                              ),
                            ]),

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

  Widget _buildSettingsCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: textColor?.withOpacity(0.7) ?? AppTheme.textSecondary,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: textColor ?? Colors.grey.shade400,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
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
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityScreen()),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/icon.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text('About nitoroute'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('nitoroute - School Transportation Management'),
            SizedBox(height: 8),
            Text('© 2024 nitoroute. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to sign out of your account? You will need to log in again to access your data.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Dispatch logout event using the screen's context
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
