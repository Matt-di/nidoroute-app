import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/notification_message.dart';

class NotificationDetailBottomSheet extends StatelessWidget {
  final NotificationMessage notification;

  const NotificationDetailBottomSheet({
    super.key,
    required this.notification,
  });

  static void show(BuildContext context, NotificationMessage notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDetailBottomSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.title).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(notification.title),
                    color: _getIconColor(notification.title),
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              notification.body,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          // Additional Details
          if (notification.data != null && notification.data!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildDataFields(notification.data!),
                ],
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Handle action based on notification type
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_getActionText(notification.title)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataFields(Map<String, dynamic> data) {
    return data.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatFieldName(entry.key)}: ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Text(
                entry.value.toString(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatFieldName(String key) {
    return key.split('_').map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
    ).join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getActionText(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return 'View Trip';
    if (t.contains('pickup') || t.contains('delivery')) return 'View Details';
    if (t.contains('emergency')) return 'View Alert';
    if (t.contains('route')) return 'View Route';
    return 'View Details';
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return Icons.directions_bus;
    if (t.contains('pickup') || t.contains('picked')) {
      return Icons.person_pin_circle;
    }
    if (t.contains('dropoff') || t.contains('delivered')) {
      return Icons.home_work;
    }
    if (t.contains('emergency') || t.contains('alert')) {
      return Icons.warning_amber_rounded;
    }
    if (t.contains('route')) return Icons.route;
    if (t.contains('performance')) return Icons.trending_up;
    if (t.contains('weather')) return Icons.cloud;
    return Icons.notifications;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return Colors.blue;
    if (t.contains('pickup') || t.contains('picked')) return Colors.orange;
    if (t.contains('dropoff') || t.contains('delivered')) return Colors.green;
    if (t.contains('emergency') || t.contains('alert')) return Colors.red;
    if (t.contains('route')) return Colors.purple;
    if (t.contains('performance')) return Colors.teal;
    if (t.contains('weather')) return Colors.cyan;
    return AppTheme.primaryColor;
  }
}
