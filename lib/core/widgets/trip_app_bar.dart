import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TripAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSharePressed;
  final Color? backgroundColor;
  final bool showBackButton;
  final bool showShareButton;

  const TripAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onSharePressed,
    this.backgroundColor,
    this.showBackButton = true,
    this.showShareButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        MediaQuery.of(context).padding.top + AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ), // Top padding for status bar
      color: backgroundColor ?? AppTheme.primaryColor,
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppTheme.textWhite,
                size: AppTheme.fontSize24,
              ),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              title,
              style: AppTheme.headlineLarge.copyWith(
                color: AppTheme.textWhite,
                fontSize: AppTheme.fontSize18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (showShareButton)
            IconButton(
              icon: Icon(
                Icons.share,
                color: AppTheme.textWhite,
                size: AppTheme.fontSize24,
              ),
              onPressed: onSharePressed ?? () {
                // TODO: Implement share functionality
              },
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + AppTheme.spacing32,
  ); // Height including status bar padding
}
