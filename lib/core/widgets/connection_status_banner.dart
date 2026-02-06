import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/connection_service.dart';
import '../services/toast_service.dart';
import '../bloc/connection_bloc.dart';
import '../bloc/base_state.dart';
import '../extensions/toast_context_extension.dart';
import '../theme/app_theme.dart';

class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  final ToastService _toastService = ToastService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, BlocState<ConnectionData>>(
      builder: (context, state) {
        // Determine visibility
        bool isVisible = false;
        if (state.isSuccess && 
            state.data?.status == ConnectionStatus.disconnected &&
            state.data?.lastChecked != null) {
          final timeSinceDisconnect = DateTime.now().difference(state.data!.lastChecked!);
          if (timeSinceDisconnect.inSeconds >= 3) {
            isVisible = true;
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
                reverseCurve: Curves.easeInBack,
              )),
              child: child,
            );
          },
          child: isVisible
              ? _buildBannerContent(context, state.data?.errorMessage) // Extract content to helper
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildBannerContent(BuildContext context, String? errorMessage) {
    final message = _getSpecificMessage(errorMessage);
    final color = _getBannerColor(errorMessage);
    final icon = _getBannerIcon(errorMessage);

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Hug content
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _retryConnection(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'RETRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSpecificMessage(String? error) {
    if (error == null) return 'Connection lost. Some features may be limited.';
    
    if (error.contains('No internet connection') || error.contains('8.8.8.8')) {
      return 'No internet connection. Please check your Wi-Fi or mobile data.';
    } else if (error.contains('Server is not reachable') || error.contains('connection refused')) {
      return 'Server is not running. Please start the backend server.';
    } else if (error.contains('Server connection timeout')) {
      return 'Server is busy or down. Please try again later.';
    } else if (error.contains('Server error occurred')) {
      return 'Server is experiencing issues. Please contact support.';
    } else if (error.contains('404') && error.contains('All endpoints failed')) {
      return 'Server is running but API endpoints are not available. Some features may be limited.';
    } else if (error.contains('404')) {
      return 'Server endpoint not found. The backend may need to be updated.';
    }
    
    return 'Backend server is not reachable. Some features may be limited.';
  }

  Color _getBannerColor(String? error) {
    if (error == null) return AppTheme.errorColor;
    
    if (error.contains('No internet connection') || error.contains('8.8.8.8')) {
      return Colors.orange; // Internet issues - orange
    } else if (error.contains('Server is not reachable') || error.contains('connection refused')) {
      return Colors.red; // Server down - red
    } else if (error.contains('404')) {
      return Colors.amber[600]!; // API endpoint issues - amber
    } else if (error.contains('timeout')) {
      return Colors.deepOrange; // Timeout issues - deep orange
    }
    
    return AppTheme.errorColor; // Default error color
  }

  IconData _getBannerIcon(String? error) {
    if (error == null) return Icons.wifi_off;
    
    if (error.contains('No internet connection') || error.contains('8.8.8.8')) {
      return Icons.signal_wifi_off; // No internet
    } else if (error.contains('Server is not reachable') || error.contains('connection refused')) {
      return Icons.error_outline; // Server down
    } else if (error.contains('404')) {
      return Icons.api; // API endpoint issues
    } else if (error.contains('timeout')) {
      return Icons.hourglass_empty; // Timeout
    }
    
    return Icons.wifi_off; // Default
  }

  Future<void> _retryConnection(BuildContext context) async {
    // Trigger connection check via BLoC
    context.read<ConnectionBloc>().add(ConnectionCheckRequested());
    
    // Show immediate feedback
    context.showWarningToast('Checking connection...');
  }
}
