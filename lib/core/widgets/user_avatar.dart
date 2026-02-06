import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final BorderRadius? borderRadius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 50.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
        color: Colors.blue[100],
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '?';
  }
}

class UserAvatarWithBorder extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color borderColor;
  final double borderWidth;

  const UserAvatarWithBorder({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 50.0,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        color: borderColor,
      ),
      child: UserAvatar(
        imageUrl: imageUrl,
        name: name,
        size: size - (borderWidth * 2),
      ),
    );
  }
}
