import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/firebase_reminder.dart';
import '../models/firebase_goal.dart';
import 'notification_service.dart';
import 'firebase_goal_service.dart';
import 'package:flutter/foundation.dart';

class FirebaseReminderService {
  static final FirebaseReminderService _instance = FirebaseReminderService._internal();
  factory FirebaseReminderService() => _instance;
  FirebaseReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseGoalService _goalService = FirebaseGoalService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Collection reference
  CollectionReference get _remindersCollection => _firestore.collection('reminders');

  // Stream of all reminders for current user (filtered for active goals only)
  Stream<List<FirebaseReminder>> get remindersStream {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _remindersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final allReminders = snapshot.docs
              .map((doc) => FirebaseReminder.fromFirestore(doc))
              .toList();
          
          // Get active goal IDs to filter reminders
          final activeGoalIds = await _getActiveGoalIds();
          
          // Filter reminders to only include those for active goals
          return allReminders.where((reminder) => 
              activeGoalIds.contains(reminder.goalId)
          ).toList();
        });
  }

  // Stream of reminders for a specific goal (only if goal is active)
  Stream<List<FirebaseReminder>> getRemindersForGoalStream(String goalId) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _remindersCollection
        .where('userId', isEqualTo: userId)
        .where('goalId', isEqualTo: goalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reminders = snapshot.docs
              .map((doc) => FirebaseReminder.fromFirestore(doc))
              .toList();
          
          // Check if goal is active
          final goal = await _goalService.getGoal(goalId);
          if (goal?.status != GoalStatus.active) {
            return <FirebaseReminder>[];
          }
          
          return reminders;
        });
  }

  // Get all reminders for current user (filtered for active goals only)
  Future<List<FirebaseReminder>> getReminders() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final allReminders = snapshot.docs
          .map((doc) => FirebaseReminder.fromFirestore(doc))
          .toList();
      
      // Get active goal IDs to filter reminders
      final activeGoalIds = await _getActiveGoalIds();
      
      // Filter reminders to only include those for active goals
      return allReminders.where((reminder) => 
          activeGoalIds.contains(reminder.goalId)
      ).toList();
    } catch (e) {
      print('Error fetching reminders: $e');
      return [];
    }
  }

  // Helper method to get active goal IDs
  Future<Set<String>> _getActiveGoalIds() async {
    try {
      final goals = await _goalService.getGoals();
      return goals
          .where((goal) => goal.status == GoalStatus.active)
          .map((goal) => goal.id)
          .toSet();
    } catch (e) {
      print('Error fetching active goals: $e');
      return <String>{};
    }
  }

  // Get reminders for a specific goal (only if goal is active)
  Future<List<FirebaseReminder>> getRemindersForGoal(String goalId) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      // Check if goal is active first
      final goal = await _goalService.getGoal(goalId);
      if (goal?.status != GoalStatus.active) {
        return [];
      }

      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .where('goalId', isEqualTo: goalId)
          .get();

      return snapshot.docs
          .map((doc) => FirebaseReminder.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching goal reminders: $e');
      return [];
    }
  }

  // Clean up reminders for non-active goals
  Future<int> cleanupRemindersForInactiveGoals() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    try {
      // Get all user's reminders
      final remindersSnapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .get();

      // Get active goal IDs
      final activeGoalIds = await _getActiveGoalIds();
      
      final batch = _firestore.batch();
      final notificationService = NotificationService();
      int deleteCount = 0;

      for (final doc in remindersSnapshot.docs) {
        final reminder = FirebaseReminder.fromFirestore(doc);
        
        // If reminder's goal is not active, delete it
        if (!activeGoalIds.contains(reminder.goalId)) {
          batch.delete(doc.reference);
          await notificationService.cancelReminderNotification(doc.id);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('✅ Cleaned up $deleteCount reminders for inactive goals');
      }
      
      return deleteCount;
    } catch (e) {
      print('Error cleaning up inactive goal reminders: $e');
      return 0;
    }
  }

  // Clean up reminders for a specific goal when it becomes inactive
  Future<void> cleanupRemindersForGoal(String goalId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .where('goalId', isEqualTo: goalId)
          .get();

      // Cancel notifications for all reminders first
      final notificationService = NotificationService();
      for (final doc in snapshot.docs) {
        await notificationService.cancelReminderNotification(doc.id);
      }

      // Then delete from Firestore
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Cleaned up ${snapshot.docs.length} reminders for goal: $goalId');
      }
    } catch (e) {
      print('Error cleaning up goal reminders: $e');
      throw Exception('Failed to delete goal reminders: $e');
    }
  }

  // Add a new reminder (only for active goals)
  Future<String?> addReminder(FirebaseReminder reminder) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if goal is active before creating reminder
      final goal = await _goalService.getGoal(reminder.goalId);
      if (goal?.status != GoalStatus.active) {
        throw Exception('Cannot create reminders for inactive goals');
      }

      final reminderWithUser = reminder.copyWith(userId: userId);
      final docRef = await _remindersCollection.add(reminderWithUser.toFirestore());
      
      // Create the final reminder with the generated ID
      final finalReminder = reminderWithUser.copyWith();
      final reminderId = docRef.id;
      
      // Schedule notification for this reminder
      final notificationService = NotificationService();
      await notificationService.scheduleReminderNotification(
        FirebaseReminder(
          id: reminderId,
          userId: finalReminder.userId,
          goalId: finalReminder.goalId,
          goalTitle: finalReminder.goalTitle,
          title: finalReminder.title,
          message: finalReminder.message,
          time: finalReminder.time,
          type: finalReminder.type,
          frequency: finalReminder.frequency,
          customDays: finalReminder.customDays,
          isActive: finalReminder.isActive,
          createdAt: finalReminder.createdAt,
          updatedAt: finalReminder.updatedAt,
          lastTriggered: finalReminder.lastTriggered,
          daysBetween: finalReminder.daysBetween,
        ),
      );
      
      return reminderId;
    } catch (e) {
      print('Error adding reminder: $e');
      throw Exception('Failed to add reminder: $e');
    }
  }

  // Update an existing reminder
  Future<void> updateReminder(String reminderId, FirebaseReminder updatedReminder) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final finalReminder = updatedReminder.copyWith(
        userId: userId,
        updatedAt: DateTime.now(),
      );
      
      await _remindersCollection.doc(reminderId).update(finalReminder.toFirestore());
      
      // Reschedule notification for this reminder
      final notificationService = NotificationService();
      await notificationService.scheduleReminderNotification(
        FirebaseReminder(
          id: reminderId,
          userId: finalReminder.userId,
          goalId: finalReminder.goalId,
          goalTitle: finalReminder.goalTitle,
          title: finalReminder.title,
          message: finalReminder.message,
          time: finalReminder.time,
          type: finalReminder.type,
          frequency: finalReminder.frequency,
          customDays: finalReminder.customDays,
          isActive: finalReminder.isActive,
          createdAt: finalReminder.createdAt,
          updatedAt: finalReminder.updatedAt,
          lastTriggered: finalReminder.lastTriggered,
          daysBetween: finalReminder.daysBetween,
        ),
      );
    } catch (e) {
      print('Error updating reminder: $e');
      throw Exception('Failed to update reminder: $e');
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      // Cancel the notification first
      final notificationService = NotificationService();
      await notificationService.cancelReminderNotification(reminderId);
      
      // Then delete from Firestore
      await _remindersCollection.doc(reminderId).delete();
    } catch (e) {
      print('Error deleting reminder: $e');
      throw Exception('Failed to delete reminder: $e');
    }
  }

  // Delete all reminders for a specific goal
  Future<void> deleteRemindersForGoal(String goalId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .where('goalId', isEqualTo: goalId)
          .get();

      // Cancel notifications for all reminders first
      final notificationService = NotificationService();
      for (final doc in snapshot.docs) {
        await notificationService.cancelReminderNotification(doc.id);
      }

      // Then delete from Firestore
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting goal reminders: $e');
      throw Exception('Failed to delete goal reminders: $e');
    }
  }

  // Toggle reminder active status
  Future<void> toggleReminder(String reminderId) async {
    try {
      final doc = await _remindersCollection.doc(reminderId).get();
      if (doc.exists) {
        final reminder = FirebaseReminder.fromFirestore(doc);
        await updateReminder(reminderId, reminder.copyWith(
          isActive: !reminder.isActive,
        ));
      }
    } catch (e) {
      print('Error toggling reminder: $e');
      throw Exception('Failed to toggle reminder: $e');
    }
  }

  // Mark reminder as triggered
  Future<void> markReminderTriggered(String reminderId) async {
    try {
      await _remindersCollection.doc(reminderId).update({
        'lastTriggered': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error marking reminder triggered: $e');
    }
  }

  // Create default reminders for a new goal
  Future<List<String>> createDefaultRemindersForGoal({
    required FirebaseGoal goal,
    List<TimeOfDay>? times,
    ReminderFrequency frequency = ReminderFrequency.everyDay,
    List<int> customDays = const [],
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final defaultTimes = times ?? [const TimeOfDay(hour: 9, minute: 0)];
    final List<String> createdReminderIds = [];

    try {
      for (final time in defaultTimes) {
        final reminder = FirebaseReminder(
          id: '', // Will be generated by Firestore
          userId: userId,
          goalId: goal.id,
          goalTitle: goal.title,
          title: 'Check-in: ${goal.title}',
          message: 'Time to work on your goal: ${goal.title}',
          time: time,
          type: ReminderType.daily,
          frequency: frequency,
          customDays: customDays,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final reminderId = await addReminder(reminder);
        if (reminderId != null) {
          createdReminderIds.add(reminderId);
        }
      }

      return createdReminderIds;
    } catch (e) {
      print('Error creating default reminders: $e');
      throw Exception('Failed to create default reminders: $e');
    }
  }

  // Get today's reminders
  Future<List<FirebaseReminder>> getTodaysReminders() async {
    final allReminders = await getReminders();
    return allReminders.where((reminder) => reminder.shouldTriggerToday()).toList()
      ..sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes.compareTo(bMinutes);
      });
  }

  // Get upcoming reminders (next 7 days)
  Future<List<ReminderSchedule>> getUpcomingReminders() async {
    final allReminders = await getReminders();
    final List<ReminderSchedule> upcoming = [];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayReminders = allReminders.where((reminder) {
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

  // Get reminder statistics
  Future<ReminderStats> getStats() async {
    final allReminders = await getReminders();
    final activeReminders = allReminders.where((r) => r.isActive).toList();
    final todaysReminders = allReminders.where((r) => r.shouldTriggerToday()).toList();
    
    final now = DateTime.now();
    final todayMinutes = now.hour * 60 + now.minute;
    final overdueReminders = allReminders.where((r) {
      if (!r.isActive) return false;
      final reminderMinutes = r.time.hour * 60 + r.time.minute;
      return r.shouldTriggerToday() && reminderMinutes < todayMinutes;
    }).toList();

    return ReminderStats(
      total: allReminders.length,
      active: activeReminders.length,
      today: todaysReminders.length,
      overdue: overdueReminders.length,
    );
  }

  // Stream version of stats
  Stream<ReminderStats> get statsStream {
    return remindersStream.map((reminders) {
      final activeReminders = reminders.where((r) => r.isActive).toList();
      final todaysReminders = reminders.where((r) => r.shouldTriggerToday()).toList();
      
      final now = DateTime.now();
      final todayMinutes = now.hour * 60 + now.minute;
      final overdueReminders = reminders.where((r) {
        if (!r.isActive) return false;
        final reminderMinutes = r.time.hour * 60 + r.time.minute;
        return r.shouldTriggerToday() && reminderMinutes < todayMinutes;
      }).toList();

      return ReminderStats(
        total: reminders.length,
        active: activeReminders.length,
        today: todaysReminders.length,
        overdue: overdueReminders.length,
      );
    });
  }

  // Stream version of upcoming reminders
  Stream<List<ReminderSchedule>> get upcomingRemindersStream {
    return remindersStream.map((allReminders) {
      final List<ReminderSchedule> upcoming = [];
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dayReminders = allReminders.where((reminder) {
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
    });
  }

  // Stream version of today's reminders
  Stream<List<FirebaseReminder>> get todaysRemindersStream {
    return remindersStream.map((allReminders) {
      return allReminders.where((reminder) => reminder.shouldTriggerToday()).toList()
        ..sort((a, b) {
          final aMinutes = a.time.hour * 60 + a.time.minute;
          final bMinutes = b.time.hour * 60 + b.time.minute;
          return aMinutes.compareTo(bMinutes);
        });
    });
  }

  // Cleanup reminders for deleted goals (call this when a goal is deleted)
  Future<void> cleanupRemindersForDeletedGoals(List<String> existingGoalIds) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final snapshot = await _remindersCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      final notificationService = NotificationService();
      int deleteCount = 0;

      for (final doc in snapshot.docs) {
        final reminder = FirebaseReminder.fromFirestore(doc);
        if (!existingGoalIds.contains(reminder.goalId)) {
          batch.delete(doc.reference);
          await notificationService.cancelReminderNotification(doc.id);
          deleteCount++;
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('Cleaned up $deleteCount orphaned reminders');
      }
    } catch (e) {
      print('Error cleaning up orphaned reminders: $e');
    }
  }

  // Initialize notification service and sync all reminders
  Future<bool> initializeNotifications() async {
    try {
      final notificationService = NotificationService();
      
      // Initialize notification service
      final initialized = await notificationService.initialize();
      if (!initialized) {
        print('Failed to initialize notification service');
        return false;
      }

      // Request permissions
      final permissionsGranted = await notificationService.requestPermissions();
      if (!permissionsGranted) {
        print('Notification permissions not granted');
        return false;
      }

      // Sync all existing reminders
      await syncAllRemindersWithNotifications();
      
      return true;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  // Sync all existing reminders with local notifications
  Future<void> syncAllRemindersWithNotifications() async {
    try {
      final reminders = await getReminders();
      final notificationService = NotificationService();
      
      // Cancel all existing notifications first
      await notificationService.cancelAllNotifications();
      
      // Schedule notifications for all active reminders
      int scheduledCount = 0;
      for (final reminder in reminders) {
        if (reminder.isActive) {
          final success = await notificationService.scheduleReminderNotification(reminder);
          if (success) scheduledCount++;
        }
      }
      
      print('✅ Synced $scheduledCount/${reminders.length} reminders with notifications');
    } catch (e) {
      print('Error syncing reminders with notifications: $e');
    }
  }

  // Test notification (for debugging)
  Future<void> sendTestNotification() async {
    final notificationService = NotificationService();
    await notificationService.showImmediateNotification(
      title: 'BackMe Test',
      body: 'This is a test notification to verify the system is working!',
      payload: 'test_notification',
    );
  }

  // Reschedule a reminder for its next occurrence (call this after a reminder fires)
  Future<void> rescheduleReminderForNextOccurrence(String reminderId) async {
    try {
      final doc = await _remindersCollection.doc(reminderId).get();
      if (!doc.exists) return;
      
      final reminder = FirebaseReminder.fromFirestore(doc);
      if (!reminder.isActive) return;
      
      // Mark as triggered
      await markReminderTriggered(reminderId);
      
      // Schedule notification for next occurrence
      final notificationService = NotificationService();
      await notificationService.scheduleReminderNotification(reminder);
      
      if (kDebugMode) {
        print('🔄 Rescheduled reminder: ${reminder.title} for next occurrence');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rescheduling reminder: $e');
      }
    }
  }

  // Initialize automatic rescheduling system
  Future<void> setupAutomaticRescheduling() async {
    // This would typically be called when a notification is tapped or when the app starts
    // For now, we'll use a simple approach of rescheduling all reminders periodically
    
    // Reschedule all active reminders to ensure they keep working
    final reminders = await getReminders();
    final notificationService = NotificationService();
    
    for (final reminder in reminders) {
      if (reminder.isActive) {
        await notificationService.scheduleReminderNotification(reminder);
      }
    }
    
    if (kDebugMode) {
      print('🔄 Set up automatic rescheduling for ${reminders.length} reminders');
    }
  }
} 