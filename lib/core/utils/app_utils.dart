import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  // Duration formatting
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
  }

  static String formatActualDuration(DateTime startTime, DateTime? endTime) {
    final end = endTime ?? DateTime.now();
    final duration = end.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  // Distance formatting
  static String formatDistance(double meters) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Time formatting
  static String formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('h:mm a').format(time);
  }

  static String formatTimeFromString(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    
    try {
      final dateTime = DateTime.tryParse(timeString);
      if (dateTime != null) {
        return DateFormat('h:mm a').format(dateTime);
      }
      
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, hour, minute);
          return DateFormat('h:mm a').format(time);
        }
      }
      
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMM dd').format(date);
  }

  // Status helpers
  static String getTripStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'delayed':
        return 'Delayed';
      default:
        return status;
    }
  }

  static Color getTripStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.orange;
      case 'in_progress':
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'delayed':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  // Progress calculations
  static double calculateProgress(int completed, int total) {
    if (total <= 0) return 0.0;
    return (completed / total).clamp(0.0, 1.0);
  }

  static String formatProgressPercentage(double progress) {
    return '${(progress * 100).toInt()}%';
  }

  // Text helpers
  static String getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '?';
    
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '?';
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phone) && phone.length >= 10;
  }

  // Color helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Number formatting
  static String formatNumber(int number) {
    return NumberFormat.decimalPattern().format(number);
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$').format(amount);
  }

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Date difference helpers
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    final difference = targetDate.difference(today).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference <= 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
