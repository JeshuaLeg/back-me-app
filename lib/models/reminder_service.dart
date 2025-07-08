import 'package:flutter/material.dart';
import 'reminder.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final List<Reminder> _reminders = [];

  // Get all reminders
  List<Reminder> get reminders => List.unmodifiable(_reminders);

  // Get reminders for a specific goal
  List<Reminder> getRemindersForGoal(String goalId) {
    return _reminders.where((reminder) => reminder.goalId == goalId).toList();
  }

  // Get active reminders
  List<Reminder> get activeReminders => _reminders.where((r) => r.isActive).toList();

  // Get today's reminders
  List<Reminder> get todaysReminders {
    return _reminders.where((reminder) => reminder.shouldTriggerToday()).toList()
      ..sort((a, b) {
        // Sort by time
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // Get upcoming reminders (next 7 days)
  List<ReminderSchedule> get upcomingReminders {
    final List<ReminderSchedule> upcoming = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
             final dayReminders = _reminders.where((reminder) {
         return reminder.isActive && reminder.shouldTriggerOnDate(date);
       }).toList();
      
      if (dayReminders.isNotEmpty) {
        dayReminders.sort((a, b) {
          final aMinutes = a.time.hour * 60 + a.time.minute;
          final bMinutes = b.time.hour * 60 + b.time.minute;
          return aMinutes.compareTo(bMinutes);
        });
        
        upcoming.add(ReminderSchedule(date: date, reminders: dayReminders));
      }
    }
    
    return upcoming;
  }

  // Add a new reminder
  void addReminder(Reminder reminder) {
    _reminders.add(reminder);
  }

  // Update an existing reminder
  void updateReminder(String id, Reminder updatedReminder) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = updatedReminder;
    }
  }

  // Delete a reminder
  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
  }

  // Delete all reminders for a goal
  void deleteRemindersForGoal(String goalId) {
    _reminders.removeWhere((r) => r.goalId == goalId);
  }

  // Toggle reminder active status
  void toggleReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isActive: !_reminders[index].isActive,
      );
    }
  }

  // Create default reminders for a goal
  List<Reminder> createDefaultRemindersForGoal({
    required String goalId,
    required String goalTitle,
    List<TimeOfDay>? times,
    ReminderFrequency frequency = ReminderFrequency.everyDay,
    List<int> customDays = const [],
  }) {
    final defaultTimes = times ?? [const TimeOfDay(hour: 9, minute: 0)];
    final List<Reminder> createdReminders = [];
    
    for (final time in defaultTimes) {
      final reminder = Reminder(
        id: '${goalId}_${time.hour}_${time.minute}_${DateTime.now().millisecondsSinceEpoch}',
        goalId: goalId,
        title: 'Check-in: $goalTitle',
        message: 'Time to work on your goal: $goalTitle',
        time: time,
        type: ReminderType.daily,
        frequency: frequency,
        customDays: customDays,
        createdAt: DateTime.now(),
      );
      
      _reminders.add(reminder);
      createdReminders.add(reminder);
    }
    
    return createdReminders;
  }

  // Mark reminder as triggered
  void markReminderTriggered(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        lastTriggered: DateTime.now(),
      );
    }
  }

  // Get reminder statistics
  ReminderStats get stats {
    final total = _reminders.length;
    final active = activeReminders.length;
    final todayCount = todaysReminders.length;
    final overdueCount = _reminders.where((r) {
      if (!r.isActive) return false;
      final now = DateTime.now();
      final todayMinutes = now.hour * 60 + now.minute;
      final reminderMinutes = r.time.hour * 60 + r.time.minute;
      return r.shouldTriggerToday() && reminderMinutes < todayMinutes;
    }).length;

    return ReminderStats(
      total: total,
      active: active,
      today: todayCount,
      overdue: overdueCount,
    );
  }

  // Initialize with sample data (for development)
  void initializeWithSampleData() {
    if (_reminders.isNotEmpty) return; // Already initialized
    
    // Sample reminders for development
    _reminders.addAll([
      Reminder(
        id: 'sample_1',
        goalId: 'sample_goal_1',
        title: 'Morning Workout Check-in',
        message: 'Time for your morning exercise routine!',
        time: const TimeOfDay(hour: 7, minute: 0),
        type: ReminderType.daily,
        frequency: ReminderFrequency.weekdays,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Reminder(
        id: 'sample_2',
        goalId: 'sample_goal_1',
        title: 'Evening Progress Review',
        message: 'How did your workout go today?',
        time: const TimeOfDay(hour: 19, minute: 30),
        type: ReminderType.daily,
        frequency: ReminderFrequency.everyDay,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Reminder(
        id: 'sample_3',
        goalId: 'sample_goal_2',
        title: 'Reading Time',
        message: 'Time to read for 30 minutes',
        time: const TimeOfDay(hour: 21, minute: 0),
        type: ReminderType.daily,
        frequency: ReminderFrequency.everyDay,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Reminder(
        id: 'sample_4',
        goalId: 'sample_goal_3',
        title: 'Weekly Goal Review',
        message: 'Time to review your weekly progress',
        time: const TimeOfDay(hour: 10, minute: 0),
        type: ReminderType.weekly,
        frequency: ReminderFrequency.custom,
        customDays: [7], // Sunday
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }
}

// Helper class for organizing reminders by date
class ReminderSchedule {
  final DateTime date;
  final List<Reminder> reminders;

  ReminderSchedule({required this.date, required this.reminders});

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = DateTime(date.year, date.month, date.day);
    
    if (reminderDate == today) {
      return 'Today';
    } else if (reminderDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }
  }
}

// Helper class for reminder statistics
class ReminderStats {
  final int total;
  final int active;
  final int today;
  final int overdue;

  ReminderStats({
    required this.total,
    required this.active,
    required this.today,
    required this.overdue,
  });
} 