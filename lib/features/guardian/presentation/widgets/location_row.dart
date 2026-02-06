import 'package:flutter/material.dart';

/// A simple row widget for displaying location information.
/// Shows an icon, label, and address text.
class LocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;
  final Color? iconColor;

  const LocationRow({
    super.key,
    required this.icon,
    required this.label,
    required this.address,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? Colors.grey.shade400, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
