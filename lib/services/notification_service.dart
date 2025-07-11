import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/firebase_reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String channelId = 'reminder_channel';
  static const String channelName = 'Goal Reminders';
  static const String channelDescription = 'Notifications for goal reminders';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Daily motivational messages for goal achievement
  static const List<String> _motivationalMessages = [
    // Success & Achievement focused
    "Success is not final, failure is not fatal: it is the courage to continue that counts. 💪",
    "The difference between ordinary and extraordinary is that little extra. ✨",
    "Your only limit is your mind. Believe in yourself and make it happen! 🌟",
    "Great things never come from comfort zones. Step forward today! 🚀",
    "A goal without a plan is just a wish. You've got the plan, now execute! 📈",
    
    // Progress & Consistency
    "Progress, not perfection. Every small step counts towards your goal! 👣",
    "Consistency is the mother of mastery. Keep showing up! 🎯",
    "Rome wasn't built in a day, but they were laying bricks every hour. 🧱",
    "Small daily improvements lead to staggering long-term results. 📊",
    "You don't have to be great to get started, but you have to get started to be great! 🌱",
    
    // Motivation & Drive
    "The best time to plant a tree was 20 years ago. The second best time is now! 🌳",
    "Your future self is watching you right now through your goals. Make them proud! 👁️",
    "Champions train when they don't feel like it. That's what separates them! 🏆",
    "The pain of discipline weighs ounces; the pain of regret weighs tons. Choose wisely! ⚖️",
    "You are what you repeatedly do. Excellence is not an act, but a habit! 🎖️",
    
    // Resilience & Perseverance
    "Fall seven times, rise eight. Your comeback story starts now! 💫",
    "Diamonds are formed under pressure. You're being shaped into something brilliant! 💎",
    "Every expert was once a beginner. Every pro was once an amateur. Keep going! 🎪",
    "The strongest people are not those who show strength in front of us, but those who win battles we know nothing about. 💝",
    "Tough times never last, but tough people do. You've got this! 💪",
    
    // Focus & Determination
    "Focus on your goal, not the obstacles. The path will become clear! 🎯",
    "A river cuts through rock not because of its power, but its persistence. 🌊",
    "Success is walking from failure to failure with no loss of enthusiasm! 🎉",
    "The goal is not to be perfect by the end. The goal is to be better today. 📈",
    "Your dedication today shapes your destiny tomorrow! 🌅",
    
    // Empowerment & Self-belief
    "You have been assigned this mountain to show others it can be moved! ⛰️",
    "Believe you can and you're halfway there. The other half is action! ⚡",
    "Your potential is endless. Your time is now. Make it count! ⏰",
    "You didn't come this far to only come this far. Keep pushing! 🔥",
    "The only impossible journey is the one you never begin! 🛤️",
    
    // Today-specific motivation
    "Today is a gift. That's why it's called the present. Use it wisely! 🎁",
    "Make today so awesome that yesterday gets jealous! 😎",
    "Today's accomplishments are tomorrow's advantages! 🏅",
    "Every day is a new opportunity to get closer to your goals! 🆕",
    "What you do today can improve all your tomorrows! 🌈"
  ];

  // Get daily motivational message based on day of year for consistency
  static String getDailyMotivationalMessage() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _motivationalMessages.length;
    return _motivationalMessages[index];
  }

  // Get device timezone
  Future<String> _getDeviceTimeZone() async {
    try {
      // Try to get system timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      
      // Map common timezone abbreviations to timezone locations
      final Map<String, String> timezoneMap = {
        'EDT': 'America/New_York',
        'EST': 'America/New_York', 
        'CDT': 'America/Chicago',
        'CST': 'America/Chicago',
        'MDT': 'America/Denver',
        'MST': 'America/Denver',
        'PDT': 'America/Los_Angeles',
        'PST': 'America/Los_Angeles',
        'UTC': 'UTC',
        'GMT': 'GMT',
      };
      
      if (timezoneMap.containsKey(timeZoneName)) {
        return timezoneMap[timeZoneName]!;
      }
      
      // Fallback to detecting based on offset
      final offset = DateTime.now().timeZoneOffset;
      if (offset.inHours == -4 || offset.inHours == -5) {
        return 'America/New_York'; // EDT/EST
      } else if (offset.inHours == -5 || offset.inHours == -6) {
        return 'America/Chicago'; // CDT/CST
      } else if (offset.inHours == -6 || offset.inHours == -7) {
        return 'America/Denver'; // MDT/MST
      } else if (offset.inHours == -7 || offset.inHours == -8) {
        return 'America/Los_Angeles'; // PDT/PST
      }
      
      // Default fallback
      return 'America/New_York';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting timezone: $e');
      }
      return 'America/New_York'; // Safe default for EDT
    }
  }

  // Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Set local timezone location
      final String timeZoneName = DateTime.now().timeZoneName;
      final String locationName = await _getDeviceTimeZone();
      if (kDebugMode) {
        print('🌍 Device timezone: $timeZoneName');
        print('🌍 Using location: $locationName');
        print('🌍 Current offset: ${DateTime.now().timeZoneOffset}');
      }

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannel();
        _isInitialized = true;
        
        if (kDebugMode) {
          print('✅ Notification service initialized successfully');
        }
        
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notification service: $e');
      }
    }
    
    return false;
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (kDebugMode) {
      print('Notification tapped with payload: $payload');
    }
    
    // Handle reminder notifications
    if (payload != null && payload.startsWith('reminder_')) {
      final reminderId = payload.replaceFirst('reminder_', '');
      
      // Reschedule the reminder for its next occurrence
      _rescheduleReminder(reminderId);
    }
  }

  // Reschedule a reminder after it has been triggered
  Future<void> _rescheduleReminder(String reminderId) async {
    try {
      // Import would be needed but for now just log
      if (kDebugMode) {
        print('🔄 Should reschedule reminder: $reminderId');
      }
      
      // In a full implementation, this would call:
      // final reminderService = FirebaseReminderService();
      // await reminderService.rescheduleReminderForNextOccurrence(reminderId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rescheduling reminder: $e');
      }
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Request basic notification permission
      final notificationStatus = await Permission.notification.request();
      
      // For Android 12+ (API 31+), also check exact alarm permission
      if (Platform.isAndroid) {
        try {
          // Check if exact alarms are allowed
          final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          final exactAlarmsAllowed = await plugin?.canScheduleExactNotifications() ?? false;
          
          if (!exactAlarmsAllowed) {
            if (kDebugMode) {
              print('⚠️ Exact alarms not allowed. App will use inexact scheduling.');
            }
            // We can still work with inexact scheduling
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not check exact alarm permission: $e');
          }
        }
      }
      
      return notificationStatus.isGranted;
    } else if (Platform.isIOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ?? false;
    }
    return false;
  }

  // Check if exact alarms are allowed
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      try {
        final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await plugin?.canScheduleExactNotifications() ?? false;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not check exact alarm permission: $e');
        }
        return false;
      }
    }
    return true; // iOS doesn't have this restriction
  }

  // Schedule a notification for a reminder
  Future<bool> scheduleReminderNotification(FirebaseReminder reminder) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Cancel existing notification for this reminder if any
      await cancelReminderNotification(reminder.id);

      if (!reminder.isActive) {
        return true; // Don't schedule inactive reminders
      }

      // Get the next trigger date
      final nextTriggerDate = reminder.getNextTriggerDate();
      
      // Ensure the date is in the future
      final now = DateTime.now();
      if (!nextTriggerDate.isAfter(now)) {
        if (kDebugMode) {
          print('❌ Next trigger date is not in the future:');
          print('   Now: $now');
          print('   Next trigger: $nextTriggerDate');
          print('   Difference: ${nextTriggerDate.difference(now).inMinutes} minutes');
        }
        return false;
      }
      
      // Get the local timezone location
      final String locationName = await _getDeviceTimeZone();
      final location = tz.getLocation(locationName);
      
      // Create the scheduled date in the correct local timezone
      final scheduledDate = tz.TZDateTime(
        location,
        nextTriggerDate.year,
        nextTriggerDate.month,
        nextTriggerDate.day,
        nextTriggerDate.hour,
        nextTriggerDate.minute,
      );
      
      // Double-check the scheduled date is also in the future
      final nowLocal = tz.TZDateTime.now(location);
      if (!scheduledDate.isAfter(nowLocal)) {
        if (kDebugMode) {
          print('❌ Scheduled date is not in the future after timezone conversion:');
          print('   Now (Local): $nowLocal');
          print('   Scheduled (Local): $scheduledDate');
          print('   Location: $locationName');
        }
        return false;
      }

      // Get motivational message
      final motivationalMessage = getDailyMotivationalMessage();

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          '${reminder.message ?? "Time to work on your goal!"}\n\n🌟 $motivationalMessage',
          contentTitle: reminder.title,
          summaryText: reminder.goalTitle,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique notification ID based on reminder ID
      final notificationId = reminder.id.hashCode;

      // Check if we can use exact scheduling
      final canUseExactAlarms = await canScheduleExactAlarms();
      final scheduleMode = canUseExactAlarms 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;

      // Schedule the notification - use single schedule for better reliability
      await _notifications.zonedSchedule(
        notificationId,
        reminder.title,
        '${reminder.message ?? "Time to work on your goal!"}\n\n🌟 $motivationalMessage',
        scheduledDate,
        notificationDetails,
        payload: 'reminder_${reminder.id}',
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // matchDateTimeComponents: _getDateTimeComponents(reminder.frequency),
      );

      if (kDebugMode) {
        final scheduleType = canUseExactAlarms ? 'exact' : 'inexact';
        print('✅ Scheduled $scheduleType notification for reminder: ${reminder.title} at $scheduledDate');
        print('   Current time: ${DateTime.now()}');
        print('   Next trigger: $nextTriggerDate');
        print('   Scheduled for: $scheduledDate');
        print('   Notification ID: $notificationId');
        print('   Frequency: ${reminder.frequency}');
        print('   Active: ${reminder.isActive}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to schedule notification for reminder ${reminder.title}: $e');
      }
      return false;
    }
  }

  // Get date time components for recurring notifications
  DateTimeComponents? _getDateTimeComponents(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.everyDay:
        return DateTimeComponents.time;
      case ReminderFrequency.weekdays:
      case ReminderFrequency.weekends:
      case ReminderFrequency.custom:
        return DateTimeComponents.dayOfWeekAndTime;
    }
  }

  // Cancel notification for a specific reminder
  Future<void> cancelReminderNotification(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await _notifications.cancel(notificationId);
    
    if (kDebugMode) {
      print('🗑️ Cancelled notification for reminder ID: $reminderId');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    
    if (kDebugMode) {
      print('🗑️ Cancelled all notifications');
    }
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    final motivationalMessage = getDailyMotivationalMessage();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      '$body\n\n🌟 $motivationalMessage',
      notificationDetails,
      payload: payload,
    );
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.checkPermissions()
              .then((permissions) => permissions?.isEnabled == true) ?? false;
    }
    return false;
  }

  // Get notification permission status information
  Future<Map<String, bool>> getPermissionStatus() async {
    final basicNotifications = await areNotificationsEnabled();
    final exactAlarms = await canScheduleExactAlarms();
    
    return {
      'notifications': basicNotifications,
      'exactAlarms': exactAlarms,
    };
  }

  // Request exact alarm permission (directs user to system settings on Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final result = await plugin?.requestExactAlarmsPermission();
        
        if (kDebugMode) {
          print('Exact alarm permission request result: $result');
        }
        
        return result ?? false;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to request exact alarm permission: $e');
        }
        return false;
      }
    }
    return true; // iOS doesn't need this
  }

  // Schedule notifications for a list of reminders
  Future<Map<String, bool>> scheduleMultipleReminders(List<FirebaseReminder> reminders) async {
    final results = <String, bool>{};
    
    for (final reminder in reminders) {
      final success = await scheduleReminderNotification(reminder);
      results[reminder.id] = success;
    }
    
    if (kDebugMode) {
      final successCount = results.values.where((success) => success).length;
      print('✅ Scheduled $successCount/${reminders.length} reminder notifications');
    }
    
    return results;
  }

  // Get a random motivational message (alternative to daily message)
  static String getRandomMotivationalMessage() {
    final random = Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  // Debug method to check and log pending notifications
  Future<void> debugPendingNotifications() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      
      if (kDebugMode) {
        print('📱 Pending notifications: ${pendingNotifications.length}');
        for (final notification in pendingNotifications) {
          print('   ID: ${notification.id}');
          print('   Title: ${notification.title}');
          print('   Body: ${notification.body}');
          print('   Payload: ${notification.payload}');
          print('   ---');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking pending notifications: $e');
      }
    }
  }
} 