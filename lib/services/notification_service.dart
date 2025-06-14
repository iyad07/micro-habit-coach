import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/user_profile.dart';
import 'ai_agent_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AIAgentService _aiAgent = AIAgentService();

  Future<void> initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request permissions for iOS
      if (Platform.isIOS) {
        await _requestIOSPermissions();
      }
      
      // Request exact alarm permission for Android 12+
      if (Platform.isAndroid) {
        await _requestAndroidExactAlarmPermission();
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      // Continue without exact alarms if permission is denied
    }
  }

  Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _requestAndroidExactAlarmPermission() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      try {
        // Check if exact alarms are permitted
        final bool? canScheduleExactAlarms = await androidImplementation.canScheduleExactNotifications();
        if (canScheduleExactAlarms == false) {
          // Request permission to schedule exact alarms
          await androidImplementation.requestExactAlarmsPermission();
        }
      } catch (e) {
        print('Error requesting exact alarm permission: $e');
        // Continue without exact alarms
      }
    }
  }

  Future<bool> _canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        try {
          return await androidImplementation.canScheduleExactNotifications() ?? false;
        } catch (e) {
          print('Error checking exact alarm permission: $e');
          return false;
        }
      }
    }
    return true; // iOS doesn't have this restriction
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleDailyReminder(UserProfile profile) async {
    if (!profile.notificationsEnabled) return;
    
    try {
      // Cancel existing reminder
      await _notifications.cancel(0);
      
      // Get a random reminder message
      final message = _aiAgent.getRandomMessage(_aiAgent.reminderMessages);
      
      // Check if we can schedule exact alarms
      final canScheduleExact = await _canScheduleExactAlarms();
      final scheduleMode = canScheduleExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      // Schedule new reminder
      await _notifications.zonedSchedule(
        0, // notification id
        'Micro-Habit Reminder 🌟',
        message,
        _nextInstanceOfTime(profile.reminderHour, profile.reminderMinute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Habit Reminders',
            channelDescription: 'Daily reminders to complete your micro-habits',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      if (!canScheduleExact) {
        print('Note: Using inexact scheduling due to system restrictions. Reminders may be slightly delayed.');
      }
    } catch (e) {
      print('Error scheduling daily reminder: $e');
      // Fallback to show immediate notification if scheduling fails
      await showMotivationalNotification();
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> showHabitCompletionNotification(String habitTitle, int streak) async {
    final message = streak == 1 
        ? 'Great job completing "$habitTitle"! Your streak starts now! 🎉'
        : 'Amazing! You\'ve completed "$habitTitle" for $streak days in a row! 🔥';
    
    await _notifications.show(
      1, // notification id
      'Habit Completed! 🎉',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_completion',
          'Habit Completion',
          channelDescription: 'Notifications when habits are completed',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showStreakMilestoneNotification(int streak) async {
    String message;
    String title;
    
    if (streak == 7) {
      title = 'One Week Streak! 🏆';
      message = 'Incredible! You\'ve maintained your habit for a full week!';
    } else if (streak == 30) {
      title = 'One Month Streak! 🌟';
      message = 'Outstanding! A full month of consistency. You\'re unstoppable!';
    } else if (streak == 100) {
      title = 'Century Streak! 💯';
      message = 'Legendary! 100 days of dedication. You\'re a habit master!';
    } else if (streak % 10 == 0) {
      title = '$streak Day Streak! 🔥';
      message = 'Amazing milestone! $streak consecutive days of building better habits!';
    } else {
      return; // Don't show notification for other numbers
    }
    
    await _notifications.show(
      2, // notification id
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_milestone',
          'Streak Milestones',
          channelDescription: 'Notifications for streak milestones',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showMotivationalNotification() async {
    final motivationalMessages = [
      'Small steps lead to big changes! Keep going! 💪',
      'You\'re building something amazing, one habit at a time! ✨',
      'Consistency is key, and you\'ve got it! 🗝️',
      'Every day you choose to grow is a victory! 🏆',
      'Your future self is cheering you on! 🎉',
    ];
    
    final message = _aiAgent.getRandomMessage(motivationalMessages);
    
    await _notifications.show(
      3, // notification id
      'You\'ve Got This! 🌟',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivational Messages',
          channelDescription: 'Motivational notifications to keep you going',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosImplementation?.requestPermissions();
      return settings == true;
    }
    return false;
  }
}