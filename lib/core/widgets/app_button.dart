import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outlined, text }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final Widget? icon;
  final AppButtonVariant variant;
  final FontWeight? fontWeight;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.fontWeight,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading && widget.onPressed != null) {
          _animationController.forward();
        }
      },
      onTapUp: (_) {
        _animationController.reverse();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              height: widget.height,
              child: _buildButton(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final content = AnimatedSwitcher(
      duration: 300.ms,
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getLoadingColor(),
                ),
              ),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: widget.fontWeight ?? _getFontWeight(),
                    color: _getTextColor(),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
    );

    switch (widget.variant) {
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _getTextColor(),
            side: BorderSide(color: _getBorderColor(), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.transparent,
          ),
          child: content,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _getTextColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: content,
        );
      case AppButtonVariant.primary:
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: _getGradient(),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            boxShadow: _getBoxShadow(),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: content,
              ),
            ),
          ),
        );
    }
  }

  Color _getLoadingColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return widget.textColor ?? AppTheme.primaryColor;
    }
  }

  Color _getTextColor() {
    if (widget.textColor != null) return widget.textColor!;
    
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppTheme.primaryColor;
    }
  }

  Color _getBorderColor() {
    return widget.backgroundColor ?? AppTheme.primaryColor;
  }

  double _getFontSize() {
    switch (widget.variant) {
      case AppButtonVariant.text:
        return 14;
      case AppButtonVariant.primary:
      case AppButtonVariant.outlined:
      default:
        return 16;
    }
  }

  FontWeight _getFontWeight() {
    switch (widget.variant) {
      case AppButtonVariant.text:
        return FontWeight.w600;
      case AppButtonVariant.primary:
      case AppButtonVariant.outlined:
      default:
        return FontWeight.w700;
    }
  }

  LinearGradient? _getGradient() {
    if (widget.backgroundColor != null) {
      return null; // Use solid color if custom background is provided
    }
    
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return null;
    }
  }

  List<BoxShadow> _getBoxShadow() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return [];
    }
  }
}
