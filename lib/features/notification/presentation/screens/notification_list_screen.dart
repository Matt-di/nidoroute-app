import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nitoroute/features/notification/logic/bloc/notification_bloc_simple.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/models/notification_message.dart';
import '../widgets/notification_detail_bottom_sheet.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch load event if state is initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<NotificationBloc>();
        if (bloc.state.isInitial) {
          bloc.add(NotificationLoadRequested());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              title: 'Notifications',
              subtitle: 'Stay updated with your trips',
              actions: [
                HeaderAction(
                  icon: Icons.done_all,
                  onPressed: () => _markAllAsRead(context),
                ),
              ],
            ),
            Expanded(
              child:
                  BlocConsumer<NotificationBloc, BlocState<List<NotificationMessage>>>(
                    listener: (context, state) {
                      // Handle any side effects here if needed
                    },
                    builder: (context, state) {
                      if (state.isLoading || state.isInitial) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.isSuccess) {
                        if (state.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async => _refreshNotifications(context),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            itemCount: state.data!.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _NotificationTile(
                                notification: state.data![index],
                              );
                            },
                          ),
                        );
                      }

                      if (state.isError) {
                        return _buildErrorState(context, state.errorMessage!);
                      }

                      return const SizedBox.shrink();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshNotifications(BuildContext context) async {
    context.read<NotificationBloc>().add(NotificationLoadRequested());
  }

  void _markAllAsRead(BuildContext context) {
    context.read<NotificationBloc>().add(NotificationMarkAllReadRequested());
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshNotifications(context),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return BlocBuilder<NotificationBloc, BlocState<List<NotificationMessage>>>(
      builder: (context, state) { 
        final isLoading = state.isLoading;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll notify you when something important happens',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Refresh',
                onPressed: isLoading
                    ? null
                    : () => _refreshNotifications(context),
                isLoading: isLoading,
                variant: AppButtonVariant.outlined,
                icon: const Icon(Icons.refresh, size: 18),
                isFullWidth: false,
                width: 120,
                height: 44,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationMessage notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // Show notification detail bottom sheet
        NotificationDetailBottomSheet.show(context, notification);

        // Mark as read if not already read
        if (!notification.isRead) {
          // Mark as read in backend
          final notificationService = context.read<NotificationService>();
          await notificationService.markAsRead(notification.id);

          // Update local state
          context.read<NotificationBloc>().add(
            NotificationMarkReadRequested(notification.id),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade100
                : AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.title).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.title),
                color: _getIconColor(notification.title),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat.jm().format(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
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
    );
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
    return Icons.notifications;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('trip')) return Colors.blue;
    if (t.contains('pickup') || t.contains('picked')) return Colors.orange;
    if (t.contains('dropoff') || t.contains('delivered')) return Colors.green;
    if (t.contains('emergency') || t.contains('alert')) return Colors.red;
    return AppTheme.primaryColor;
  }
}
