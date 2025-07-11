import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReminderType {
  daily,
  weekly,
  custom,
}

enum ReminderFrequency {
  everyDay,
  weekdays,
  weekends,
  custom,
}

extension ReminderFrequencyExtension on ReminderFrequency {
  String getDescription() {
    switch (this) {
      case ReminderFrequency.everyDay:
        return 'Every day';
      case ReminderFrequency.weekdays:
        return 'Weekdays only';
      case ReminderFrequency.weekends:
        return 'Weekends only';
      case ReminderFrequency.custom:
        return 'Custom days';
    }
  }
}

class FirebaseReminder {
  final String id;
  final String userId;
  final String goalId;
  final String goalTitle; // Store goal title for easy reference
  final String title;
  final String? message;
  final TimeOfDay time;
  final ReminderType type;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1-7 representing Monday-Sunday
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastTriggered;
  final int daysBetween; // For custom frequency

  const FirebaseReminder({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.goalTitle,
    required this.title,
    this.message,
    required this.time,
    required this.type,
    required this.frequency,
    this.customDays = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastTriggered,
    this.daysBetween = 1,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'goalId': goalId,
      'goalTitle': goalTitle,
      'title': title,
      'message': message,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'type': type.name,
      'frequency': frequency.name,
      'customDays': customDays,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastTriggered': lastTriggered != null ? Timestamp.fromDate(lastTriggered!) : null,
      'daysBetween': daysBetween,
    };
  }

  // Create from Firestore document
  factory FirebaseReminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseReminder(
      id: doc.id,
      userId: data['userId'] ?? '',
      goalId: data['goalId'] ?? '',
      goalTitle: data['goalTitle'] ?? '',
      title: data['title'] ?? '',
      message: data['message'],
      time: TimeOfDay(
        hour: data['timeHour'] ?? 9,
        minute: data['timeMinute'] ?? 0,
      ),
      type: ReminderType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ReminderType.daily,
      ),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => ReminderFrequency.everyDay,
      ),
      customDays: List<int>.from(data['customDays'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastTriggered: (data['lastTriggered'] as Timestamp?)?.toDate(),
      daysBetween: data['daysBetween'] ?? 1,
    );
  }

  // Helper method to check if reminder should trigger today
  bool shouldTriggerToday() {
    if (!isActive) return false;
    
    final today = DateTime.now();
    final weekday = today.weekday; // 1 = Monday, 7 = Sunday
    
    switch (frequency) {
      case ReminderFrequency.everyDay:
        return true;
      case ReminderFrequency.weekdays:
        return weekday >= 1 && weekday <= 5; // Monday to Friday
      case ReminderFrequency.weekends:
        return weekday == 6 || weekday == 7; // Saturday and Sunday
      case ReminderFrequency.custom:
        return customDays.contains(weekday);
    }
  }

  // Helper method to check if reminder should trigger on a specific date
  bool shouldTriggerOnDate(DateTime date) {
    if (!isActive) return false;
    
    final weekday = date.weekday;
    
    switch (frequency) {
      case ReminderFrequency.everyDay:
        return true;
      case ReminderFrequency.weekdays:
        return weekday >= 1 && weekday <= 5;
      case ReminderFrequency.weekends:
        return weekday == 6 || weekday == 7;
      case ReminderFrequency.custom:
        return customDays.contains(weekday);
    }
  }

  // Helper method to get next trigger date
  DateTime getNextTriggerDate() {
    final now = DateTime.now();
    
    // Start with today at the reminder time
    var nextDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If the time today has already passed, or if it's within the next 5 minutes, start from tomorrow
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    if (nextDate.isBefore(fiveMinutesFromNow)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    
    // Find the next valid day based on frequency
    int attempts = 0;
    while (!shouldTriggerOnDate(nextDate) && attempts < 7) {
      nextDate = nextDate.add(const Duration(days: 1));
      attempts++;
    }
    
    // Safety check: ensure we always return a future date
    if (nextDate.isBefore(now.add(const Duration(minutes: 1)))) {
      nextDate = now.add(const Duration(hours: 1)); // Fallback to 1 hour from now
    }
    
    return nextDate;
  }

  // Helper method to get human-readable frequency description
  String getFrequencyDescription() {
    switch (frequency) {
      case ReminderFrequency.everyDay:
        return 'Every day';
      case ReminderFrequency.weekdays:
        return 'Weekdays only';
      case ReminderFrequency.weekends:
        return 'Weekends only';
      case ReminderFrequency.custom:
        if (customDays.isEmpty) return 'Custom';
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selectedDays = customDays.map((day) => dayNames[day - 1]).toList();
        return selectedDays.join(', ');
    }
  }

  // Helper method to format time
  String getFormattedTime() {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Copy method for updates
  FirebaseReminder copyWith({
    String? userId,
    String? goalId,
    String? goalTitle,
    String? title,
    String? message,
    TimeOfDay? time,
    ReminderType? type,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? lastTriggered,
    int? daysBetween,
  }) {
    return FirebaseReminder(
      id: id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      goalTitle: goalTitle ?? this.goalTitle,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastTriggered: lastTriggered ?? this.lastTriggered,
      daysBetween: daysBetween ?? this.daysBetween,
    );
  }
}

// Helper class for grouping reminders by date
class ReminderSchedule {
  final DateTime date;
  final List<FirebaseReminder> reminders;

  const ReminderSchedule({
    required this.date,
    required this.reminders,
  });
}

// Stats class for reminder analytics
class ReminderStats {
  final int total;
  final int active;
  final int today;
  final int overdue;

  const ReminderStats({
    required this.total,
    required this.active,
    required this.today,
    required this.overdue,
  });
} 