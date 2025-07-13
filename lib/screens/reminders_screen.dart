import 'package:flutter/material.dart';
import 'dart:async';
import '../models/firebase_reminder.dart';
import '../models/firebase_goal.dart';
import '../services/firebase_reminder_service.dart';
import '../services/firebase_goal_service.dart';
import '../services/notification_service.dart';
import '../utils/date_formatter.dart';
import '../main.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FirebaseReminderService _reminderService = FirebaseReminderService();
  final FirebaseGoalService _goalService = FirebaseGoalService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<List<FirebaseGoal>>? _goalStatusSubscription;

  @override
  void initState() {
    super.initState();
    _setupGoalStatusListener();
    _checkNotificationPermissions();
  }

  @override
  void dispose() {
    _goalStatusSubscription?.cancel();
    super.dispose();
  }

  // Listen to goal status changes and clean up reminders for inactive goals
  void _setupGoalStatusListener() {
    _goalStatusSubscription = _goalService.goalsStream.listen((goals) async {
      // Clean up reminders for goals that are no longer active
      await _reminderService.cleanupRemindersForInactiveGoals();
    });
  }

  // Check notification permissions and show warning if needed
  Future<void> _checkNotificationPermissions() async {
    final permissions = await _notificationService.getPermissionStatus();
    
    if (!permissions['notifications']! || !permissions['exactAlarms']!) {
      if (mounted) {
        _showPermissionWarning(permissions);
      }
    }
  }

  // Show permission warning dialog
  void _showPermissionWarning(Map<String, bool> permissions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppTheme.warningAmber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Notification Setup',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!permissions['notifications']!)
              _buildPermissionItem(
                'Basic Notifications',
                'Required for reminder alerts',
                permissions['notifications']!,
                false,
              ),
            if (!permissions['exactAlarms']!)
              _buildPermissionItem(
                'Exact Alarms',
                'For precise reminder timing',
                permissions['exactAlarms']!,
                true,
              ),
            const SizedBox(height: 16),
            Text(
              'For the best reminder experience, please enable the missing permissions.',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _handlePermissionRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningAmber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enable Permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, bool isGranted, bool isExactAlarm) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.error,
            color: isGranted ? AppTheme.successGreen : AppTheme.errorRose,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.lightText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle permission requests
  Future<void> _handlePermissionRequest() async {
    try {
      // First request basic notifications
      await _notificationService.requestPermissions();
      
      // Then request exact alarms if needed
      final canScheduleExact = await _notificationService.canScheduleExactAlarms();
      if (!canScheduleExact) {
        final exactPermissionGranted = await _notificationService.requestExactAlarmPermission();
        
        if (!exactPermissionGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Exact alarms permission needed for precise reminders. You can enable it later in app settings.'),
              backgroundColor: AppTheme.warningAmber,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      
      // Re-sync notifications after permission changes
      await _reminderService.syncAllRemindersWithNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissions updated! Reminders will now work properly.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up permissions: $e'),
            backgroundColor: AppTheme.errorRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _checkAndShowPermissionStatus(),
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Notification Settings',
          ),
          IconButton(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.notifications_active_rounded),
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded),
            onPressed: _debugPendingNotifications,
            tooltip: 'Debug Notifications',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.medical_services_rounded),
            tooltip: 'System Diagnostic',
            onSelected: (value) {
              switch (value) {
                case 'full_diagnostic':
                  _runFullSystemDiagnostic();
                  break;
                case 'health_check':
                  _runQuickHealthCheck();
                  break;
                case 'open_settings':
                  _showSystemSettingsGuidance();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'full_diagnostic',
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Full System Diagnostic'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'health_check',
                child: Row(
                  children: [
                    Icon(Icons.favorite_border_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Quick Health Check'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Settings Guidance'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showAddReminderDialog(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primarySlate.withValues(alpha: 0.05),
              const Color(0xFF0F172A),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: StreamBuilder<ReminderStats>(
          stream: _reminderService.statsStream,
          builder: (context, statsSnapshot) {
            return StreamBuilder<List<FirebaseReminder>>(
              stream: _reminderService.remindersStream,
              builder: (context, remindersSnapshot) {
                final stats = statsSnapshot.data ?? ReminderStats(
                  total: 0,
                  active: 0,
                  today: 0,
                  overdue: 0,
                );

                final reminders = remindersSnapshot.data ?? [];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsSection(stats),
                            const SizedBox(height: 32),
                            _buildRemindersSection(reminders),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(ReminderStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentIndigo.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkAccentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Reminder Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.total.toString(),
                  Icons.notifications_rounded,
                  AppTheme.accentIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  stats.active.toString(),
                  Icons.notifications_active_rounded,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Today',
                  stats.today.toString(),
                  Icons.today_rounded,
                  AppTheme.warningAmber,
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(List<FirebaseReminder> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.darkSuccessGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'My Reminders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const Spacer(),
            Text(
              '${reminders.length} reminders',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (reminders.isEmpty)
          _buildEmptyState()
        else
          ...reminders.map((reminder) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReminderCard(reminder),
          )),
      ],
    );
  }

  Widget _buildReminderCard(FirebaseReminder reminder) {
    final isToday = reminder.shouldTriggerToday();

    return GestureDetector(
      onTap: () => _showEditReminderDialog(reminder),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday
                ? AppTheme.successGreen.withValues(alpha: 0.3)
                : reminder.isActive 
                    ? AppTheme.accentIndigo.withValues(alpha: 0.2)
                    : AppTheme.mutedText.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.successGreen.withValues(alpha: 0.2)
                        : reminder.isActive 
                            ? AppTheme.accentIndigo.withValues(alpha: 0.2)
                            : AppTheme.mutedText.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isToday
                        ? Icons.today_rounded
                        : Icons.access_time_rounded,
                    color: isToday
                        ? AppTheme.successGreen
                        : reminder.isActive 
                            ? AppTheme.accentIndigo 
                            : AppTheme.mutedText,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: reminder.isActive ? AppTheme.lightText : AppTheme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.goalTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reminder.getFormattedTime(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? AppTheme.successGreen
                            : reminder.isActive 
                                ? AppTheme.accentIndigo 
                                : AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.successGreen.withValues(alpha: 0.2)
                            : AppTheme.mutedText.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isToday
                            ? 'Today'
                            : reminder.frequency.getDescription(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? AppTheme.successGreen
                              : AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Switch(
                  value: reminder.isActive,
                  onChanged: (value) => _toggleReminder(reminder.id),
                  activeColor: AppTheme.successGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (reminder.message != null && reminder.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message_rounded,
                      size: 16,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reminder.message!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.mutedText.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.warningAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: AppTheme.warningAmber,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Reminders Set',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create reminders for your goals to stay on track and never miss important check-ins.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddReminderDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentIndigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReminder(String reminderId) async {
    try {
      await _reminderService.toggleReminder(reminderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling reminder: $e'),
            backgroundColor: AppTheme.errorRose,
          ),
        );
      }
    }
  }

  Future<void> _showAddReminderDialog() async {
    final allGoals = await _goalService.getGoals();
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active).toList();
    
    if (activeGoals.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No active goals available. Create an active goal first to set reminders.'),
            backgroundColor: AppTheme.warningAmber,
            action: SnackBarAction(
              label: 'Create Goal',
              textColor: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AddReminderDialog(
          goals: activeGoals,
          onSave: (reminder) async {
            try {
              await _reminderService.addReminder(reminder);
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Reminder created successfully!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted && context.mounted) {
                String errorMessage = 'Error creating reminder: $e';
                
                // Provide user-friendly error messages
                if (e.toString().contains('must be a date in the future')) {
                  errorMessage = 'Please set the reminder time at least 5 minutes in the future.';
                } else if (e.toString().contains('Cannot create reminders for inactive goals')) {
                  errorMessage = 'Cannot create reminders for inactive goals. Please select an active goal.';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: AppTheme.errorRose,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          },
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    // Show dialog to select test delay
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '🧪 Test Notification',
          style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Schedule a test notification in:',
              style: TextStyle(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            ...[-1, 1, 2, 5].map((minutes) => ListTile(
              title: Text(
                minutes == -1 ? 'Immediately' : '$minutes minute${minutes == 1 ? '' : 's'}',
                style: TextStyle(color: AppTheme.lightText),
              ),
              onTap: () => Navigator.of(context).pop(minutes),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.mutedText)),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        if (result == -1) {
          // Send immediate notification
          await _notificationService.showImmediateNotification(
            title: '🧪 Test Notification',
            body: 'This is an immediate test notification. If you received this, basic notifications are working!',
            payload: 'test_immediate',
          );
        } else {
          // Schedule test notification
          await _notificationService.scheduleTestNotification(minutesFromNow: result);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == -1 
                ? 'Immediate test notification sent!' 
                : 'Test notification scheduled for $result minute${result == 1 ? '' : 's'} from now!'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending test notification: $e'),
              backgroundColor: AppTheme.errorRose,
            ),
          );
        }
      }
    }
  }

  Future<void> _debugPendingNotifications() async {
    try {
      // Get debug information
      final pendingNotifications = await _notificationService.getPendingNotifications();
      final permissions = await _notificationService.getPermissionStatus();
      final channelStatus = await _notificationService.getNotificationChannelStatus();
      
      // Also print to console for detailed debugging
      await _notificationService.debugPendingNotifications();
      
      if (mounted) {
        _showNotificationDebugDialog(pendingNotifications, permissions, channelStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error debugging notifications: $e'),
            backgroundColor: AppTheme.errorRose,
          ),
        );
      }
    }
  }

  void _showNotificationDebugDialog(
    List<dynamic> pendingNotifications, 
    Map<String, bool> permissions, 
    Map<String, dynamic> channelStatus
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bug_report_rounded, color: AppTheme.warningAmber, size: 24),
            const SizedBox(width: 12),
            Text(
              'Notification Debug',
              style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Time
                _buildDebugSection(
                  '📅 Current Status',
                  [
                    'Time: ${DateTime.now().toString().substring(0, 19)}',
                    'Timezone: ${DateTime.now().timeZoneName}',
                    'Offset: ${DateTime.now().timeZoneOffset}',
                  ],
                ),
                
                // Permissions
                _buildDebugSection(
                  '🔐 Permissions',
                  [
                    'Basic Notifications: ${(permissions['notifications'] ?? false) ? '✅ Granted' : '❌ Denied'}',
                    'Exact Alarms: ${(permissions['exactAlarms'] ?? false) ? '✅ Granted' : '❌ Denied'}',
                  ],
                ),
                
                // Pending Notifications
                _buildDebugSection(
                  '📱 Pending Notifications (${pendingNotifications.length})',
                  pendingNotifications.isEmpty 
                    ? ['❌ No pending notifications found!', 
                       'This might indicate:', 
                       '• Notifications were not scheduled',
                       '• Android cancelled them',
                       '• Battery optimization interference']
                    : pendingNotifications.map((n) => 
                        '• ID: ${n.id}\n  ${n.title ?? 'No title'}\n  ${(n.body ?? 'No body').substring(0, 50)}...').toList(),
                ),
                
                // Troubleshooting Guide
                _buildDebugSection(
                  '🛠️ Troubleshooting Tips',
                  [
                    '1. Check: Settings > Apps > Back Me App > Notifications',
                    '2. Disable battery optimization for this app',
                    '3. Make sure Do Not Disturb isn\'t blocking notifications',
                    '4. Try restarting the app after changing permissions',
                    '5. Use "Test Notification" to verify basic functionality',
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendTestNotification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningAmber,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Test Notification'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.accentIndigo,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primarySlate.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.mutedText.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item,
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditReminderDialog(FirebaseReminder reminder) async {
    final allGoals = await _goalService.getGoals();
    final activeGoals = allGoals.where((goal) => goal.status == GoalStatus.active).toList();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => EditReminderDialog(
          reminder: reminder,
          goals: activeGoals,
          onSave: (updatedReminder) async {
            try {
              await _reminderService.updateReminder(reminder.id, updatedReminder);
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Reminder updated successfully!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating reminder: $e'),
                    backgroundColor: AppTheme.errorRose,
                  ),
                );
              }
            }
          },
          onDelete: () async {
            try {
              await _reminderService.deleteReminder(reminder.id);
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Reminder deleted successfully!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting reminder: $e'),
                    backgroundColor: AppTheme.errorRose,
                  ),
                );
              }
            }
          },
        ),
      );
    }
  }

  // Check and show current permission status
  Future<void> _checkAndShowPermissionStatus() async {
    final permissions = await _notificationService.getPermissionStatus();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: AppTheme.accentIndigo,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Notification Settings',
                style: TextStyle(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionItem(
                'Basic Notifications',
                'Required for reminder alerts',
                permissions['notifications']!,
                false,
              ),
              _buildPermissionItem(
                'Exact Alarms',
                'For precise reminder timing',
                permissions['exactAlarms']!,
                true,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: AppTheme.accentIndigo,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reminders work with inexact alarms but may be slightly delayed.',
                        style: TextStyle(
                          color: AppTheme.accentIndigo,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppTheme.mutedText),
              ),
            ),
            if (!permissions['notifications']! || !permissions['exactAlarms']!)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _handlePermissionRequest();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Fix Permissions'),
              ),
          ],
        ),
      );
    }
  }

  // Comprehensive system diagnostic methods
  Future<void> _runFullSystemDiagnostic() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                'Running system diagnostic...',
                style: TextStyle(color: AppTheme.lightText),
              ),
            ],
          ),
        ),
      );

      // Run diagnostic
      final diagnostic = await _notificationService.performSystemDiagnostic();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show results dialog
      if (mounted) {
        _showDiagnosticResults(diagnostic);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic failed: $e'),
            backgroundColor: AppTheme.errorRose,
          ),
        );
      }
    }
  }

  Future<void> _runQuickHealthCheck() async {
    try {
      final healthStatus = await _notificationService.getSystemHealthStatus();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  healthStatus.startsWith('🟢') ? Icons.check_circle : 
                  healthStatus.startsWith('🟡') ? Icons.warning : Icons.error,
                  color: healthStatus.startsWith('🟢') ? AppTheme.successGreen :
                         healthStatus.startsWith('🟡') ? AppTheme.warningAmber : AppTheme.errorRose,
                ),
                const SizedBox(width: 8),
                Text(
                  'Health Check',
                  style: TextStyle(color: AppTheme.lightText),
                ),
              ],
            ),
            content: Text(
              healthStatus,
              style: TextStyle(color: AppTheme.mutedText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: AppTheme.accentIndigo)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health check failed: $e'),
            backgroundColor: AppTheme.errorRose,
          ),
        );
      }
    }
  }

  void _showSystemSettingsGuidance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.settings, color: AppTheme.accentIndigo),
            const SizedBox(width: 8),
            Text(
              'Settings Guidance',
              style: TextStyle(color: AppTheme.lightText),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To ensure reliable notifications, please check these settings:',
                style: TextStyle(color: AppTheme.lightText, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                '🔋 Battery Optimization',
                'Settings > Apps > Back Me App > Battery > Unrestricted',
                'Set to "Unrestricted" or "Don\'t optimize"',
              ),
              _buildSettingsItem(
                '🔔 Notifications',
                'Settings > Apps > Back Me App > Notifications',
                'Enable all notification permissions',
              ),
              _buildSettingsItem(
                '⏰ Exact Alarms',
                'Settings > Apps > Back Me App > Special app access > Alarms & reminders',
                'Allow setting alarms and reminders',
              ),
              _buildSettingsItem(
                '🚀 Auto-start',
                'Settings > Battery > Auto-start management',
                'Enable auto-start for this app (if available)',
              ),
              _buildSettingsItem(
                '🌙 Do Not Disturb',
                'Settings > Sounds > Do Not Disturb',
                'Make sure app notifications aren\'t blocked',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it', style: TextStyle(color: AppTheme.accentIndigo)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(String title, String path, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.lightText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            path,
            style: TextStyle(
              color: AppTheme.accentIndigo,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticResults(Map<String, dynamic> diagnostic) {
    final permissions = diagnostic['permissions'] as Map<String, dynamic>? ?? {};
    final notifications = diagnostic['notifications'] as Map<String, dynamic>? ?? {};
    final recommendations = diagnostic['recommendations'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: AppTheme.errorRose),
            const SizedBox(width: 8),
            Text(
              'System Diagnostic',
              style: TextStyle(color: AppTheme.lightText),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Permissions Status
                _buildDiagnosticSection(
                  '🔐 Permissions',
                  permissions.entries.map((e) => 
                    '${e.key}: ${e.value == true ? "✅ Granted" : "❌ Denied"}'
                  ).toList(),
                ),
                
                // Notification Status
                _buildDiagnosticSection(
                  '📱 Notifications',
                  [
                    'Pending: ${notifications['pending_count'] ?? 0}',
                    if ((notifications['pending_count'] ?? 0) == 0)
                      '⚠️ No pending notifications found!',
                  ],
                ),
                
                // Recommendations
                if (recommendations.isNotEmpty) ...[
                  Text(
                    '💡 Recommendations',
                    style: TextStyle(
                      color: AppTheme.lightText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendations.take(5).map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $rec',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  )),
                  if (recommendations.length > 5)
                    Text(
                      '... and ${recommendations.length - 5} more',
                      style: TextStyle(
                        color: AppTheme.accentIndigo,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: AppTheme.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSystemSettingsGuidance();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentIndigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fix Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              item,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
                fontFamily: item.contains('✅') || item.contains('❌') ? 'monospace' : null,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  final List<FirebaseGoal> goals;
  final Function(FirebaseReminder) onSave;

  const AddReminderDialog({
    super.key,
    required this.goals,
    required this.onSave,
  });

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  FirebaseGoal? _selectedGoal;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  ReminderFrequency _selectedFrequency = ReminderFrequency.everyDay;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Add Reminder',
        style: TextStyle(
          color: AppTheme.lightText,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FirebaseGoal>(
              value: _selectedGoal,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Select a goal',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
              style: TextStyle(color: AppTheme.lightText),
              dropdownColor: AppTheme.darkCard,
              items: widget.goals.map((goal) => DropdownMenuItem(
                value: goal,
                child: Text(
                  goal.title,
                  style: TextStyle(color: AppTheme.lightText),
                ),
              )).toList(),
              onChanged: (goal) {
                setState(() {
                  _selectedGoal = goal;
                  if (goal != null && _titleController.text.isEmpty) {
                    _titleController.text = 'Check-in: ${goal.title}';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            
            Text(
              'Title',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Reminder title',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Message (Optional)',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              style: TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Optional reminder message',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(color: AppTheme.lightText),
                              ),
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.accentIndigo,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency',
                        style: TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ReminderFrequency>(
                        value: _selectedFrequency,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.darkSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: TextStyle(color: AppTheme.lightText),
                        dropdownColor: AppTheme.darkCard,
                        items: ReminderFrequency.values.map((freq) => DropdownMenuItem(
                          value: freq,
                          child: Text(
                            freq.getDescription(),
                            style: TextStyle(color: AppTheme.lightText, fontSize: 12),
                          ),
                        )).toList(),
                        onChanged: (freq) {
                          if (freq != null) {
                            setState(() {
                              _selectedFrequency = freq;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.mutedText),
          ),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveReminder : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  bool _canSave() {
    return _selectedGoal != null && _titleController.text.trim().isNotEmpty;
  }

  void _saveReminder() {
    if (!_canSave()) return;

    final reminder = FirebaseReminder(
      id: '', // Will be generated by Firestore
      userId: '', // Will be set by service
      goalId: _selectedGoal!.id,
      goalTitle: _selectedGoal!.title,
      title: _titleController.text.trim(),
      message: _messageController.text.trim().isNotEmpty 
          ? _messageController.text.trim() 
          : null,
      time: _selectedTime,
      type: ReminderType.daily,
      frequency: _selectedFrequency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(reminder);
    Navigator.of(context).pop();
  }
}

// Edit Reminder Dialog
class EditReminderDialog extends StatefulWidget {
  final FirebaseReminder reminder;
  final List<FirebaseGoal> goals;
  final Function(FirebaseReminder) onSave;
  final VoidCallback onDelete;

  const EditReminderDialog({
    super.key,
    required this.reminder,
    required this.goals,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditReminderDialog> createState() => _EditReminderDialogState();
}

class _EditReminderDialogState extends State<EditReminderDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  late FirebaseGoal? _selectedGoal;
  late TimeOfDay _selectedTime;
  late ReminderFrequency _selectedFrequency;
  late List<int> _customDays;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.reminder.title;
    _messageController.text = widget.reminder.message ?? '';
    _selectedGoal = widget.goals.firstWhere(
      (goal) => goal.id == widget.reminder.goalId,
      orElse: () => widget.goals.first,
    );
    _selectedTime = widget.reminder.time;
    _selectedFrequency = widget.reminder.frequency;
    _customDays = List.from(widget.reminder.customDays);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Text(
            'Edit Reminder',
            style: TextStyle(
              color: AppTheme.lightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation();
            },
            icon: Icon(
              Icons.delete_rounded,
              color: AppTheme.errorRose,
            ),
            tooltip: 'Delete Reminder',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FirebaseGoal>(
              value: _selectedGoal,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Select a goal',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
              style: TextStyle(color: AppTheme.lightText),
              dropdownColor: AppTheme.darkCard,
              items: widget.goals.map((goal) => DropdownMenuItem(
                value: goal,
                child: Text(
                  goal.title,
                  style: TextStyle(color: AppTheme.lightText),
                ),
              )).toList(),
              onChanged: (goal) {
                setState(() {
                  _selectedGoal = goal;
                });
              },
            ),
            const SizedBox(height: 16),
            
            Text(
              'Title',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Reminder title',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Message (Optional)',
              style: TextStyle(
                color: AppTheme.lightText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              style: TextStyle(color: AppTheme.lightText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Optional reminder message',
                hintStyle: TextStyle(color: AppTheme.mutedText),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              _selectedTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(color: AppTheme.lightText),
                              ),
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.accentIndigo,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency',
                        style: TextStyle(
                          color: AppTheme.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ReminderFrequency>(
                        value: _selectedFrequency,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.darkSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: TextStyle(color: AppTheme.lightText),
                        dropdownColor: AppTheme.darkCard,
                        items: ReminderFrequency.values.map((freq) => DropdownMenuItem(
                          value: freq,
                          child: Text(
                            freq.getDescription(),
                            style: TextStyle(color: AppTheme.lightText, fontSize: 12),
                          ),
                        )).toList(),
                        onChanged: (freq) {
                          if (freq != null) {
                            setState(() {
                              _selectedFrequency = freq;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Custom days selection for custom frequency
            if (_selectedFrequency == ReminderFrequency.custom) ...[
              const SizedBox(height: 16),
              Text(
                'Custom Days',
                style: TextStyle(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildCustomDaysSelector(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.mutedText),
          ),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _saveReminder : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildCustomDaysSelector() {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1-7 for Monday-Sunday
        final isSelected = _customDays.contains(dayNumber);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _customDays.remove(dayNumber);
              } else {
                _customDays.add(dayNumber);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.accentIndigo.withValues(alpha: 0.2)
                  : AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.accentIndigo
                    : AppTheme.mutedText.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              dayNames[index],
              style: TextStyle(
                color: isSelected ? AppTheme.accentIndigo : AppTheme.mutedText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _canSave() {
    return _selectedGoal != null && 
           _titleController.text.trim().isNotEmpty &&
           (_selectedFrequency != ReminderFrequency.custom || _customDays.isNotEmpty);
  }

  void _saveReminder() {
    if (!_canSave()) return;

    final updatedReminder = widget.reminder.copyWith(
      goalId: _selectedGoal!.id,
      goalTitle: _selectedGoal!.title,
      title: _titleController.text.trim(),
      message: _messageController.text.trim().isNotEmpty 
          ? _messageController.text.trim() 
          : null,
      time: _selectedTime,
      frequency: _selectedFrequency,
      customDays: _selectedFrequency == ReminderFrequency.custom ? _customDays : [],
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedReminder);
    Navigator.of(context).pop();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Reminder',
          style: TextStyle(
            color: AppTheme.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this reminder? This action cannot be undone.',
          style: TextStyle(
            color: AppTheme.mutedText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 