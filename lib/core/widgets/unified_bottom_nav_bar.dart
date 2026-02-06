import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import 'navigation_manager.dart';

class UnifiedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole;

  const UnifiedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _getNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final titles = NavigationManager.getScreenTitlesForRole(userRole);

    return titles.map((title) {
      return BottomNavigationBarItem(
        icon: _getIconForTitle(title, false),
        activeIcon: _getIconForTitle(title, true),
        label: title,
      );
    }).toList();
  }

  Widget _getIconForTitle(String title, bool isActive) {
    IconData iconData;
    switch (title.toLowerCase()) {
      case 'home':
      case 'dashboard':
        iconData = isActive ? Icons.home_filled : Icons.home_outlined;
        break;
      case 'routes':
        iconData = isActive ? Icons.map : Icons.map_outlined;
        break;
      case 'trip history':
      case 'monitoring':
      case 'analytics':
        iconData = isActive ? Icons.analytics : Icons.analytics_outlined;
        break;
      case 'notifications':
        iconData = isActive
            ? Icons.notifications
            : Icons.notifications_outlined;
        break;
      case 'settings':
      case 'profile':
        iconData = isActive ? Icons.person : Icons.person_outline;
        break;
      default:
        iconData = isActive ? Icons.circle : Icons.circle_outlined;
    }

    return Icon(iconData)
        .animate(target: isActive ? 1 : 0)
        .scaleXY(
          begin: 1.0,
          end: 1.2,
          duration: 200.ms,
          curve: Curves.easeOutBack,
        )
        .tint(color: AppTheme.primaryColor);
  }
}
