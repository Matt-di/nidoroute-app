import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFormSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const AppFormSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85, // Limit to 85% of screen height
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: padding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
            
            // Footer / Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!.map((action) {
                    final isLast = action == actions!.last;
                    return Padding(
                      padding: EdgeInsets.only(left: isLast ? 12 : 0),
                      child: action,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => AppFormSheet(
        title: title,
        padding: padding,
        actions: actions,
        child: child,
      ),
    );
  }
}
