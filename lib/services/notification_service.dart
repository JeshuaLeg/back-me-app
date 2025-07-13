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

      // Ensure local timezone is properly set
      final location = tz.getLocation(locationName);
      tz.setLocalLocation(location);
      
      if (kDebugMode) {
        final nowLocal = tz.TZDateTime.now(tz.local);
        final nowDevice = DateTime.now();
        print('🌍 TZ Local time: $nowLocal');
        print('🌍 Device time: $nowDevice');
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

  // Convert DateTime to TZDateTime in local timezone (without assuming UTC input)
  tz.TZDateTime _toLocalTZDateTime(DateTime dateTime) {
    // Use the local timezone directly with the date/time components
    return tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
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
      
      // Convert to TZDateTime in local timezone (no UTC assumption)
      final scheduledDate = _toLocalTZDateTime(nextTriggerDate);
      
      // Double-check the scheduled date is also in the future
      final nowLocal = tz.TZDateTime.now(tz.local);
      if (!scheduledDate.isAfter(nowLocal)) {
        if (kDebugMode) {
          print('❌ Scheduled date is not in the future after timezone conversion:');
          print('   Now (Local): $nowLocal');
          print('   Scheduled (Local): $scheduledDate');
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
        print('✅ Scheduled $scheduleType notification for reminder: ${reminder.title}');
        print('   Current time: ${DateTime.now()} (${DateTime.now().timeZoneName})');
        print('   Next trigger: $nextTriggerDate (Local DateTime)');
        print('   Scheduled for: $scheduledDate (Local TZDateTime)');
        print('   Notification ID: $notificationId');
        print('   Frequency: ${reminder.frequency}');
        print('   Active: ${reminder.isActive}');
        print('   Time difference: ${scheduledDate.difference(nowLocal).inMinutes} minutes from now');
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
        print('📱 NOTIFICATION DEBUG REPORT');
        print('==============================');
        print('📅 Current time: ${DateTime.now()}');
        print('🌍 Local timezone: ${DateTime.now().timeZoneName} (${DateTime.now().timeZoneOffset})');
        print('📱 Pending notifications: ${pendingNotifications.length}');
        print('');
        
        if (pendingNotifications.isEmpty) {
          print('⚠️ NO PENDING NOTIFICATIONS FOUND!');
          print('   This could mean:');
          print('   1. Notifications were not scheduled successfully');
          print('   2. Android cancelled them due to app restrictions');
          print('   3. Battery optimization is interfering');
          print('   4. Exact alarm permission was revoked');
        } else {
          for (final notification in pendingNotifications) {
            print('📋 Notification ID: ${notification.id}');
            print('   Title: ${notification.title}');
            print('   Body: ${notification.body}');
            print('   Payload: ${notification.payload}');
            print('   ---');
          }
        }
        
        // Check permissions
        final permissions = await getPermissionStatus();
        print('');
        print('🔐 PERMISSIONS STATUS:');
        print('   Basic notifications: ${(permissions['notifications'] ?? false) ? '✅' : '❌'}');
        print('   Exact alarms: ${(permissions['exactAlarms'] ?? false) ? '✅' : '❌'}');
        
        // Check battery optimization (Android only)
        if (Platform.isAndroid) {
          print('');
          print('🔋 BATTERY OPTIMIZATION CHECK:');
          print('   If notifications aren\'t working, check:');
          print('   1. Settings > Apps > Back Me App > Battery > Unrestricted');
          print('   2. Settings > Battery > Battery optimization > Back Me App > Don\'t optimize');
          print('   3. Make sure Do Not Disturb is not blocking app notifications');
        }
        
        print('==============================');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in notification debug: $e');
      }
    }
  }

  // Comprehensive system diagnostic for notification delivery issues
  Future<Map<String, dynamic>> performSystemDiagnostic() async {
    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'permissions': {},
      'notifications': {},
      'system': {},
      'recommendations': <String>[],
    };

    try {
      // Basic permission check
      final permissions = await getPermissionStatus();
      diagnostic['permissions'] = permissions;

      // Pending notifications check
      final pendingNotifications = await getPendingNotifications();
      diagnostic['notifications'] = {
        'pending_count': pendingNotifications.length,
        'pending_notifications': pendingNotifications.map((n) => {
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'payload': n.payload,
        }).toList(),
      };

      // System-specific checks
      if (Platform.isAndroid) {
        await _performAndroidSystemDiagnostic(diagnostic);
      } else if (Platform.isIOS) {
        await _performiOSSystemDiagnostic(diagnostic);
      }

      // Generate recommendations based on findings
      _generateRecommendations(diagnostic);

      if (kDebugMode) {
        print('');
        print('🔍 COMPREHENSIVE SYSTEM DIAGNOSTIC');
        print('=====================================');
        _printDiagnosticReport(diagnostic);
        print('=====================================');
      }

    } catch (e) {
      diagnostic['error'] = e.toString();
      if (kDebugMode) {
        print('❌ Error in system diagnostic: $e');
      }
    }

    return diagnostic;
  }

  // Android-specific system diagnostic
  Future<void> _performAndroidSystemDiagnostic(Map<String, dynamic> diagnostic) async {
    final systemInfo = <String, dynamic>{};

    try {
      // Check if running on emulator
      final isEmulator = await _isRunningOnEmulator();
      systemInfo['is_emulator'] = isEmulator;
      
      if (isEmulator) {
        systemInfo['emulator_warning'] = {
          'detected': true,
          'impact': 'Scheduled notifications may not work reliably',
          'reason': 'Emulators have aggressive power management and limited AlarmManager simulation',
          'solution': 'Test on a real Android device for accurate results',
          'immediate_notifications': 'Should work normally',
          'scheduled_notifications': 'May fail to deliver',
        };
      }

      // Check notification channel status
      final channelStatus = await getNotificationChannelStatus();
      systemInfo['notification_channel'] = channelStatus;

      // Check if app can schedule exact alarms
      final canScheduleExact = await canScheduleExactAlarms();
      systemInfo['can_schedule_exact_alarms'] = canScheduleExact;

      // Check Android version (affects notification behavior)
      systemInfo['android_sdk_int'] = 'Unknown'; // Would need platform channel
      
      // Battery optimization hints
      systemInfo['battery_optimization_hints'] = {
        'check_required': !isEmulator,
        'settings_path': 'Settings > Apps > Back Me App > Battery',
        'optimization_setting': 'Should be set to "Unrestricted" or "Don\'t optimize"',
        'emulator_note': isEmulator ? 'Not applicable in emulator' : null,
      };

      // Auto-start management (common on Chinese ROMs)
      systemInfo['auto_start_management'] = {
        'check_required': !isEmulator,
        'common_locations': [
          'Settings > Apps > Back Me App > Auto-start',
          'Settings > Battery > Auto-start management',
          'Settings > Power management > Auto-start',
        ],
        'note': isEmulator ? 'Not applicable in emulator' : 'Enable auto-start for reliable notifications',
      };

      // Doze mode and app standby
      systemInfo['doze_mode'] = {
        'affected': !isEmulator,
        'solution': isEmulator ? 'Test on real device' : 'Add app to battery optimization whitelist',
        'note': isEmulator 
            ? 'Emulator may not properly simulate Doze mode'
            : 'Android may put app to sleep after extended inactivity',
      };

      // Do Not Disturb
      systemInfo['dnd_check'] = {
        'check_required': !isEmulator,
        'note': isEmulator 
            ? 'Emulator may not have DND settings'
            : 'Verify Do Not Disturb is not blocking app notifications',
        'settings_path': 'Settings > Sounds > Do Not Disturb',
      };

    } catch (e) {
      systemInfo['error'] = e.toString();
    }

    diagnostic['system'] = systemInfo;
  }

  // iOS-specific system diagnostic
  Future<void> _performiOSSystemDiagnostic(Map<String, dynamic> diagnostic) async {
    final systemInfo = <String, dynamic>{};

    try {
      // iOS notification settings
      systemInfo['notification_settings'] = {
        'check_required': true,
        'settings_path': 'Settings > Notifications > Back Me App',
        'required_settings': [
          'Allow Notifications: ON',
          'Lock Screen: ON',
          'Notification Center: ON',
          'Banners: ON',
          'Sounds: ON (recommended)',
        ],
      };

      // Focus modes (iOS 15+)
      systemInfo['focus_modes'] = {
        'check_required': true,
        'note': 'Check if Focus/Do Not Disturb modes are blocking notifications',
        'settings_path': 'Settings > Focus',
      };

      // Low Power Mode
      systemInfo['low_power_mode'] = {
        'affects_notifications': true,
        'note': 'Low Power Mode may delay notifications',
        'settings_path': 'Settings > Battery > Low Power Mode',
      };

    } catch (e) {
      systemInfo['error'] = e.toString();
    }

    diagnostic['system'] = systemInfo;
  }

  // Generate recommendations based on diagnostic findings
  void _generateRecommendations(Map<String, dynamic> diagnostic) {
    final recommendations = <String>[];
    final permissions = diagnostic['permissions'] as Map<String, dynamic>? ?? {};
    final notifications = diagnostic['notifications'] as Map<String, dynamic>? ?? {};
    final system = diagnostic['system'] as Map<String, dynamic>? ?? {};

    // Check if running on emulator
    final isEmulator = system['is_emulator'] as bool? ?? false;
    
    // Emulator-specific recommendations
    if (isEmulator) {
      recommendations.add('🤖 EMULATOR DETECTED: Scheduled notifications may not work reliably');
      recommendations.add('🔥 CRITICAL: Test on a real Android device for accurate results');
      recommendations.add('📱 EMULATOR LIMITATION: Only immediate notifications work reliably in emulators');
      
      final pendingCount = notifications['pending_count'] as int? ?? 0;
      if (pendingCount > 0) {
        recommendations.add('✅ GOOD: Notifications are being scheduled (${pendingCount} pending)');
        recommendations.add('⚠️ BUT: They may not fire due to emulator power management');
      }
    }

    // Permission-based recommendations
    if (permissions['notifications'] != true) {
      recommendations.add('CRITICAL: Enable notification permissions in Settings > Apps > Back Me App > Notifications');
    }

    if (permissions['exactAlarms'] != true && Platform.isAndroid) {
      recommendations.add('IMPORTANT: Enable exact alarms in Settings > Apps > Back Me App > Special app access > Alarms & reminders');
    }

    // Notification count recommendations (adjust for emulator)
    final pendingCount = notifications['pending_count'] as int? ?? 0;
    if (pendingCount == 0 && !isEmulator) {
      recommendations.add('CRITICAL: No pending notifications found - app restrictions may be cancelling them');
      recommendations.add('Check battery optimization settings immediately');
    }

    // Platform-specific recommendations (skip for emulator)
    if (Platform.isAndroid && !isEmulator) {
      recommendations.addAll([
        'ESSENTIAL: Set battery usage to "Unrestricted" in Settings > Apps > Back Me App > Battery',
        'ESSENTIAL: Disable battery optimization for this app in Settings > Battery > Battery optimization',
        'CHECK: Enable auto-start management if available on your device',
        'VERIFY: Do Not Disturb is not blocking app notifications',
        'TIP: Keep app in recent apps to prevent it from being killed',
      ]);
    } else if (Platform.isAndroid && isEmulator) {
      recommendations.addAll([
        'TESTING: Try immediate notifications (they should work)',
        'TESTING: Deploy to real device to test scheduled notifications',
        'DEVELOPMENT: Use flutter run --release for more realistic testing',
        'ALTERNATIVE: Use Firebase Test Lab for cloud device testing',
      ]);
    } else if (Platform.isIOS) {
      recommendations.addAll([
        'VERIFY: All notification settings are enabled in Settings > Notifications > Back Me App',
        'CHECK: Focus modes are not blocking notifications',
        'AVOID: Low Power Mode may delay notifications',
      ]);
    }

    diagnostic['recommendations'] = recommendations;
  }

  // Print diagnostic report to console
  void _printDiagnosticReport(Map<String, dynamic> diagnostic) {
    final permissions = diagnostic['permissions'] as Map<String, dynamic>? ?? {};
    final notifications = diagnostic['notifications'] as Map<String, dynamic>? ?? {};
    final system = diagnostic['system'] as Map<String, dynamic>? ?? {};
    final recommendations = diagnostic['recommendations'] as List<dynamic>? ?? [];

    print('📅 Timestamp: ${diagnostic['timestamp']}');
    print('📱 Platform: ${diagnostic['platform']}');
    print('');

    // Permissions
    print('🔐 PERMISSIONS:');
    permissions.forEach((key, value) {
      final status = value == true ? '✅ GRANTED' : '❌ DENIED';
      print('   $key: $status');
    });
    print('');

    // Notifications
    print('📱 NOTIFICATIONS:');
    print('   Pending count: ${notifications['pending_count']}');
    final pendingNotifs = notifications['pending_notifications'] as List<dynamic>? ?? [];
    for (final notif in pendingNotifs) {
      print('   • ${notif['title']} (ID: ${notif['id']})');
    }
    print('');

    // System info
    print('⚙️ SYSTEM INFO:');
    system.forEach((key, value) {
      print('   $key: $value');
    });
    print('');

    // Recommendations
    print('💡 RECOMMENDATIONS:');
    for (int i = 0; i < recommendations.length; i++) {
      print('   ${i + 1}. ${recommendations[i]}');
    }
  }

  // Quick system health check (simplified version)
  Future<String> getSystemHealthStatus() async {
    try {
      final permissions = await getPermissionStatus();
      final pendingCount = (await getPendingNotifications()).length;
      
      // Quick health assessment
      if (permissions['notifications'] != true) {
        return '🔴 CRITICAL: Notification permission denied';
      }
      
      if (pendingCount == 0) {
        return '🟠 WARNING: No pending notifications (possible system restrictions)';
      }
      
      if (permissions['exactAlarms'] != true && Platform.isAndroid) {
        return '🟡 CAUTION: Exact alarms disabled (notifications may be delayed)';
      }
      
      return '🟢 HEALTHY: All basic checks passed';
    } catch (e) {
      return '🔴 ERROR: Health check failed - $e';
    }
  }

  // Check if running on emulator
  Future<bool> _isRunningOnEmulator() async {
    try {
      // Check for common emulator indicators
      const emulatorIndicators = [
        'goldfish', 'ranchu', 'sdk_gphone', 'generic', 'emulator',
        'vbox86', 'emu64', 'android_x86'
      ];
      
      // This is a simplified check - in a real implementation you'd use
      // platform channels to get device info
      return Platform.isAndroid && !kReleaseMode;
    } catch (e) {
      return false;
    }
  }

  // Enhanced test notification with emulator warning
  Future<void> scheduleTestNotification({int minutesFromNow = 1}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) print('❌ Cannot schedule test - service not initialized');
        return;
      }
    }

    // Check if running on emulator
    final isEmulator = await _isRunningOnEmulator();
    if (isEmulator && kDebugMode) {
      print('⚠️ EMULATOR DETECTED - Scheduled notifications may not work reliably');
      print('   For reliable testing, use a real Android device');
      print('   Emulators often have aggressive power management that prevents scheduled notifications');
    }

    try {
      // Add a buffer to ensure the date is definitely in the future
      final now = DateTime.now();
      final testTime = now.add(Duration(minutes: minutesFromNow, seconds: 10));
      final scheduledDate = _toLocalTZDateTime(testTime);
      
      // Get current time in the same timezone format for comparison
      final nowLocal = tz.TZDateTime.now(tz.local);
      
      if (kDebugMode) {
        print('🧪 Test notification scheduling:');
        print('   Device now: $now (${now.timeZoneName})');
        print('   TZ Local now: $nowLocal');
        print('   Test time: $testTime (Local DateTime)');
        print('   Scheduled: $scheduledDate (Local TZDateTime)');
        print('   Time diff: ${scheduledDate.difference(nowLocal).inSeconds} seconds');
        
        if (isEmulator) {
          print('   ⚠️ EMULATOR WARNING: This may not fire due to emulator limitations');
        }
      }
      
      // Verify the scheduled date is in the future
      if (!scheduledDate.isAfter(nowLocal)) {
        if (kDebugMode) {
          print('❌ Test notification: Scheduled date is not in the future');
          print('   Now (TZ): $nowLocal');
          print('   Scheduled: $scheduledDate');
          print('   Difference: ${scheduledDate.difference(nowLocal).inSeconds} seconds');
        }
        return;
      }
      
      // Use a unique ID for test notifications
      final testId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
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

      // Check exact alarm capability
      final canUseExactAlarms = await canScheduleExactAlarms();
      final scheduleMode = canUseExactAlarms 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;

      String notificationBody = 'This is a test notification scheduled for ${scheduledDate.toString()}. If you received this, notifications are working!';
      
      if (isEmulator) {
        notificationBody = '🤖 EMULATOR TEST: $notificationBody\n\nNote: Emulators may not reliably deliver scheduled notifications. Test on a real device for accurate results.';
      }

      await _notifications.zonedSchedule(
        testId,
        '🧪 Test Notification',
        notificationBody,
        scheduledDate,
        notificationDetails,
        payload: 'test_notification',
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      if (kDebugMode) {
        final scheduleType = canUseExactAlarms ? 'exact' : 'inexact';
        print('✅ Scheduled $scheduleType TEST notification');
        print('   Test ID: $testId');
        print('   Minutes from now: $minutesFromNow');
        print('   ✅ Successfully scheduled for: $scheduledDate');
        
        if (isEmulator) {
          print('   ⚠️ EMULATOR: May not fire - test on real device for reliable results');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to schedule test notification: $e');
      }
    }
  }

  // Check notification channel status (Android only)
  Future<Map<String, dynamic>> getNotificationChannelStatus() async {
    if (!Platform.isAndroid) {
      return {'platform': 'ios', 'supported': false};
    }

    try {
      final plugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // This is a simplified check - in a real app you might use native code
      // to get more detailed channel information
      return {
        'platform': 'android',
        'supported': true,
        'channelId': channelId,
        'channelName': channelName,
        'note': 'Use system settings to verify channel is not blocked',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking notification channel: $e');
      }
      return {'error': e.toString()};
    }
  }
} 