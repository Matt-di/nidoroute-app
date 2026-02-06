import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<HeaderAction>? actions;
  final bool showBackButton;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null)
                Row(
                  children: actions!.map((action) => _buildActionButton(context, action)).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, HeaderAction action) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(action.icon, color: AppTheme.textPrimary),
            onPressed: action.onPressed,
          ),
          if (action.badgeCount != null && action.badgeCount! > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HeaderAction {
  final IconData icon;
  final VoidCallback onPressed;
  final int? badgeCount;

  HeaderAction({
    required this.icon,
    required this.onPressed,
    this.badgeCount,
  });
}
