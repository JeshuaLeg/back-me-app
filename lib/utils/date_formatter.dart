import 'package:intl/intl.dart';

class DateFormatter {
  // Standard MM/dd/yyyy format
  static final DateFormat _standardFormat = DateFormat('MM/dd/yyyy');
  
  // Short format for space-constrained areas
  static final DateFormat _shortFormat = DateFormat('M/d/yy');
  
  // Long format for detailed views
  static final DateFormat _longFormat = DateFormat('MMMM d, yyyy');
  
  // Time format
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  
  // Date and time format
  static final DateFormat _dateTimeFormat = DateFormat('MM/dd/yyyy h:mm a');

  /// Format date as MM/dd/yyyy
  static String formatDate(DateTime date) {
    return _standardFormat.format(date);
  }

  /// Format date as M/d/yy (short format)
  static String formatDateShort(DateTime date) {
    return _shortFormat.format(date);
  }

  /// Format date as "Month d, yyyy" (long format)
  static String formatDateLong(DateTime date) {
    return _longFormat.format(date);
  }

  /// Format time as "h:mm AM/PM"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Format date and time as "MM/dd/yyyy h:mm AM/PM"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format relative time (e.g., "2 days ago", "Just now")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date for display in lists or cards
  static String formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }

  /// Format deadline with context (e.g., "Due in 3 days", "Overdue by 2 days")
  static String formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = deadlineDate.difference(today).inDays;

    if (difference > 0) {
      return 'Due in $difference day${difference != 1 ? 's' : ''}';
    } else if (difference == 0) {
      return 'Due today';
    } else {
      final overdueDays = difference.abs();
      return 'Overdue by $overdueDays day${overdueDays != 1 ? 's' : ''}';
    }
  }

  /// Format date range (e.g., "01/15/2024 - 02/15/2024")
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Format day of week (e.g., "Monday", "Tuesday")
  static String formatDayOfWeek(DateTime date) {
    final format = DateFormat('EEEE');
    return format.format(date);
  }
} 