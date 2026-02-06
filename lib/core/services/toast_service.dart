import 'package:flutter/material.dart';

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  void show(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    ToastPosition position = ToastPosition.bottom,
  }) {
    if (_isShowing) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        position: position,
        onDismiss: hide,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;

    // Auto dismiss after duration
    Future.delayed(duration, () {
      hide();
    });
  }

  void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green,
      position: ToastPosition.top,
    );
  }

  void showError(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red,
      position: ToastPosition.top,
      duration: const Duration(seconds: 4),
    );
  }

  void showWarning(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.orange,
      position: ToastPosition.top,
    );
  }

  void hide() {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }
}

enum ToastPosition {
  top,
  center,
  bottom,
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final ToastPosition position;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    
    double top;
    switch (widget.position) {
      case ToastPosition.top:
        top = topPadding + 50.0;
        break;
      case ToastPosition.center:
        top = mediaQuery.size.height * 0.5;
        break;
      case ToastPosition.bottom:
        top = mediaQuery.size.height - 150.0;
        break;
    }

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(_animation),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForColor(widget.backgroundColor),
                  color: widget.textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(
                    Icons.close,
                    color: widget.textColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForColor(Color color) {
    if (color == Colors.green) return Icons.check_circle;
    if (color == Colors.red) return Icons.error;
    if (color == Colors.orange) return Icons.warning;
    return Icons.info;
  }
}
