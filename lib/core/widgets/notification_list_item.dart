import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/notification_message.dart';

/// A list item widget for displaying notifications.
/// Shows icon based on notification type, title, body, and timestamp.
class NotificationListItem extends StatelessWidget {
  final NotificationMessage notification;
  final VoidCallback? onTap;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                _getIconColor(notification.title).withOpacity(0.02),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getIconColor(notification.title),
                      _getIconColor(notification.title).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getIconColor(notification.title).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(notification.title),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTimestamp(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return Icons.directions_bus;
    if (t.contains('pickup') || t.contains('picked')) return Icons.person_add;
    if (t.contains('dropoff') || t.contains('dropped')) return Icons.person_remove;
    if (t.contains('delay') || t.contains('late')) return Icons.warning_amber;
    if (t.contains('arrive') || t.contains('arrived')) return Icons.location_on;
    if (t.contains('complete') || t.contains('finished')) return Icons.check_circle;
    if (t.contains('start') || t.contains('began')) return Icons.play_arrow;
    if (t.contains('cancel')) return Icons.cancel;
    return Icons.notifications;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return const Color(0xFF3B82F6);
    if (t.contains('pickup') || t.contains('picked')) return const Color(0xFF10B981);
    if (t.contains('dropoff') || t.contains('dropped')) return const Color(0xFF06B6D4);
    if (t.contains('delay') || t.contains('late')) return const Color(0xFFF59E0B);
    if (t.contains('arrive') || t.contains('arrived')) return const Color(0xFF8B5CF6);
    if (t.contains('complete') || t.contains('finished')) return const Color(0xFF10B981);
    if (t.contains('start') || t.contains('began')) return const Color(0xFF3B82F6);
    if (t.contains('cancel')) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }
}
