import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A card that displays the status of a journey step (pickup or dropoff).
/// Used in guardian tracking and completed trip screens.
class JourneyStatusCard extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final DateTime? timestamp;
  final IconData icon;
  final Color color;

  const JourneyStatusCard({
    super.key,
    required this.title,
    required this.isCompleted,
    this.timestamp,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [color.withOpacity(0.1), color.withOpacity(0.05)]
              : [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? color.withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompleted ? color : Colors.grey.shade600,
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(timestamp!),
              style: TextStyle(
                fontSize: 10,
                color: isCompleted ? color.withOpacity(0.8) : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
