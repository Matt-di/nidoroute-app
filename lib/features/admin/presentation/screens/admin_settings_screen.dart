import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../auth/logic/bloc/auth_bloc.dart';
import '../../../auth/logic/bloc/auth_event.dart';
import '../../../notification/presentation/screens/notification_list_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, BlocState<AuthData>>(
      builder: (context, authState) {
        if (!authState.isSuccess || authState.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.data!.user;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const DashboardHeader(
                  title: 'Settings',
                  subtitle: 'Customize your app experience',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Account Section
                      _buildSettingsSection(
                        'Account',
                        Icons.account_circle_outlined,
                        [
                          _buildSettingsItem(
                            Icons.notifications_outlined,
                            'Notifications',
                            'Manage notification preferences',
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationListScreen(),
                              ),
                            ),
                          ),
                          _buildSettingsItem(
                            Icons.security_outlined,
                            'Privacy & Security',
                            'Control your privacy settings',
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _showPrivacyDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Preferences Section
                      _buildSettingsSection(
                        'Preferences',
                        Icons.settings_outlined,
                        [
                          _buildSwitchItem(
                            Icons.location_on_outlined,
                            'Location Services',
                            'Allow app to access your location',
                            _locationServicesEnabled,
                            (value) {
                              setState(() => _locationServicesEnabled = value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // App Section
                      _buildSettingsSection(
                        'App',
                        Icons.app_settings_alt_outlined,
                        [
                          _buildSettingsItem(
                            Icons.info_outline,
                            'About',
                            'App version and information',
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),


                      const SizedBox(height: 48),

                      // Logout Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSettingsItem(
                              Icons.logout,
                              'Logout',
                              'Sign out of your account',
                              textColor: Colors.red,
                              iconColor: Colors.red,
                              onTap: () => _showLogoutDialog(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(
    String title,
    IconData icon,
    List<Widget> items,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
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
          ),
          const Divider(height: 1),
          // Section Items
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          textColor?.withOpacity(0.7) ?? AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your privacy is important to us.'),
            SizedBox(height: 16),
            Text('• We collect minimal personal data'),
            Text('• Location data is used only for trip tracking'),
            Text('• All data is encrypted and secure'),
            Text('• You can delete your account anytime'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About School Transport'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A comprehensive school transportation management system.'),
            SizedBox(height: 16),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Real-time trip monitoring'),
            Text('• Driver and vehicle management'),
            Text('• Student and guardian tracking'),
            Text('• Route optimization'),
            Text('• Push notifications'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
