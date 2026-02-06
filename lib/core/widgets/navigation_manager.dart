import 'package:flutter/material.dart';
import 'package:nitoroute/features/driver/presentation/screens/trip_history_screen.dart' show TripHistoryScreen;
import '../../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../../features/guardian/presentation/screens/guardian_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/manage_routes_screen.dart';
import '../../features/admin/presentation/screens/manage_drivers_screen.dart';
import '../../features/admin/presentation/screens/manage_passengers_screen.dart';
import '../../features/admin/presentation/screens/trip_monitoring_screen.dart';
import '../../features/admin/presentation/screens/manage_staff_screen.dart';
import '../../features/admin/presentation/screens/manage_guardians_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/notification/presentation/screens/notification_list_screen.dart';

class NavigationManager {
  static List<Widget> getScreensForRole(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return _getDriverScreens();
      case 'guardian':
        return _getGuardianScreens();
      case 'admin':
        return _getAdminScreens();
      default:
        return _getDriverScreens(); // Default fallback
    }
  }

  static List<Widget> _getDriverScreens() {
    return [
      const DriverDashboardScreen(), // Home
      const TripHistoryScreen(), // Analytics (trip history)
      const NotificationListScreen(), // Notifications
      const SettingsScreen(), // Profile/Settings
    ];
  }

  static List<Widget> _getGuardianScreens() {
    return [
      const GuardianDashboardScreen(), // Home - children status & tracking
      const NotificationListScreen(), // Notifications - alerts about children
      const SettingsScreen(), // Settings - preferences & profile
    ];
  }

  static List<Widget> _getAdminScreens() {
    return [
      const AdminDashboardScreen(), // Home
      const ManageRoutesScreen(), // Routes
      const TripMonitoringScreen(), // Analytics (monitoring)
      const NotificationListScreen(), // Notifications
      const AdminSettingsScreen(), // Profile/Settings (admin settings)
    ];
  }

  static String getScreenTitle(int index, String role) {
    final titles = getScreenTitlesForRole(role);
    return titles[index];
  }

  static List<String> getScreenTitlesForRole(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return [
          'Dashboard',
          'Trip History',
          'Notifications',
          'Settings',
        ];
      case 'guardian':
        return [
          'Home', // Dashboard - children status & tracking
          'Notifications', // Alerts about children
          'Settings', // Preferences & profile
        ];
      case 'admin':
        return [
          'Dashboard',
          'Routes',
          'Monitoring',
          'Notifications',
          'Settings',
        ];
      default:
        return [
          'Dashboard',
          'Routes',
          'Analytics',
          'Notifications',
          'Settings',
        ];
    }
  }

  static bool shouldShowFab(int index, String role) {
    // Show FAB only on home screens for certain roles
    if (index != 0) return false; // Only on home tab

    switch (role.toLowerCase()) {
      case 'admin':
        return true; // Admin can add/manage items
      default:
        return false;
    }
  }

  static void handleFabPress(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        // Show admin management menu
        _showAdminManagementMenu(context);
        break;
      case 'guardian':
        // Show contact options
        _showGuardianContactOptions(context);
        break;
      default:
        break;
    }
  }

  static void _showAdminManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true, // Allow full screen height if needed
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.8, // Max 80% of screen height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMenuItem(context, Icons.badge, 'Drivers', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageDriversScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(context, Icons.map, 'Routes', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageRoutesScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(context, Icons.child_care, 'Passengers', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManagePassengersScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(
                      context,
                      Icons.family_restroom,
                      'Guardians',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageGuardiansScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(context, Icons.monitor_heart, 'Trips', () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TripMonitoringScreen(),
                        ),
                      );
                    }),
                    _buildMenuItem(
                      context,
                      Icons.admin_panel_settings,
                      'Staff',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageStaffScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void _showGuardianContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(
              context,
              Icons.chat_bubble_outline,
              'Contact Bus Driver',
              () => Navigator.pop(context), // TODO: Implement contact driver
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              Icons.support_agent,
              'Contact Support',
              () => Navigator.pop(context), // TODO: Implement contact support
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
