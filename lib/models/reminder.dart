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

class Reminder {
  final String id;
  final String goalId;
  final String title;
  final String? message;
  final TimeOfDay time;
  final ReminderType type;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1-7 representing Monday-Sunday
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int daysBetween; // For custom frequency

  Reminder({
    required this.id,
    required this.goalId,
    required this.title,
    this.message,
    required this.time,
    required this.type,
    required this.frequency,
    this.customDays = const [],
    this.isActive = true,
    required this.createdAt,
    this.lastTriggered,
    this.daysBetween = 1,
  });

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

  // Helper method to get next trigger date
  DateTime getNextTriggerDate() {
    final now = DateTime.now();
    var nextDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If today's time has passed, start from tomorrow
    if (nextDate.isBefore(now)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    
    // Find the next valid day
    while (!shouldTriggerOnDate(nextDate)) {
      nextDate = nextDate.add(const Duration(days: 1));
    }
    
    return nextDate;
  }

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
  Reminder copyWith({
    String? title,
    String? message,
    TimeOfDay? time,
    ReminderType? type,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isActive,
    DateTime? lastTriggered,
    int? daysBetween,
  }) {
    return Reminder(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      daysBetween: daysBetween ?? this.daysBetween,
    );
  }

  // Convert to/from Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'message': message,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'type': type.index,
      'frequency': frequency.index,
      'customDays': customDays,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastTriggered': lastTriggered?.millisecondsSinceEpoch,
      'daysBetween': daysBetween,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      goalId: map['goalId'],
      title: map['title'],
      message: map['message'],
      time: TimeOfDay(hour: map['timeHour'], minute: map['timeMinute']),
      type: ReminderType.values[map['type']],
      frequency: ReminderFrequency.values[map['frequency']],
      customDays: List<int>.from(map['customDays'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastTriggered: map['lastTriggered'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTriggered'])
          : null,
      daysBetween: map['daysBetween'] ?? 1,
    );
  }
} 