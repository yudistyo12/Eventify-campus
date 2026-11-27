import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/event_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _canScheduleExactNotifications = false;
  bool get _canUsePlugin => !kIsWeb && _isInitialized;

  /// Initialize notification service — call once in main.dart
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    _isInitialized = true;
    if (kDebugMode) print('[NotificationService] Initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      var canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        await androidPlugin.requestExactAlarmsPermission();
        canScheduleExact =
            await androidPlugin.canScheduleExactNotifications() ?? false;
      }
      _canScheduleExactNotifications = canScheduleExact;
      if (!canScheduleExact && kDebugMode) {
        debugPrint(
          '[NotificationService] Exact alarm access denied; using inexact scheduling.',
        );
      }
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('[NotificationService] Tapped: ${response.payload}');
    }
  }

  // =============================================
  // NOTIFICATION CHANNEL CONFIGURATION
  // =============================================

  static const _eventChannel = AndroidNotificationDetails(
    'eventify_events',
    'Event Notifications',
    channelDescription: 'Notifikasi saat event dibuat, diubah, atau dihapus',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFF6366F1),
    enableVibration: true,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'eventify_reminders',
    'Event Reminders',
    channelDescription: 'Pengingat sebelum event dimulai',
    importance: Importance.max,
    priority: Priority.max,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
    color: Color(0xFFF59E0B),
    enableVibration: true,
  );

  // =============================================
  // INSTANT NOTIFICATIONS
  // =============================================

  /// Show notification when a new event is created
  Future<void> showEventCreatedNotification(EventModel event) async {
    if (!_canUsePlugin) return;
    await _plugin.show(
      event.id.hashCode,
      '✅ Event Baru Ditambahkan',
      '${event.name} — ${event.category}\n📍 ${event.location}',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_created:${event.id}',
    );
  }

  /// Show notification when an event is updated
  Future<void> showEventUpdatedNotification(EventModel event) async {
    if (!_canUsePlugin) return;
    await _plugin.show(
      event.id.hashCode + 1000,
      '✏️ Event Diperbarui',
      '${event.name} telah diperbarui\n📍 ${event.location}',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_updated:${event.id}',
    );
  }

  /// Show notification when an event is deleted
  Future<void> showEventDeletedNotification(String eventName) async {
    if (!_canUsePlugin) return;
    await _plugin.show(
      eventName.hashCode + 2000,
      '🗑️ Event Dihapus',
      '"$eventName" telah dihapus dari daftar event',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'event_deleted',
    );
  }

  /// Show FCM notifications while the app is in the foreground.
  Future<void> showRemoteMessage(RemoteMessage message) async {
    if (!_canUsePlugin) return;
    final notification = message.notification;
    if (notification == null) return;

    final eventIdValue = message.data['eventId'];
    final eventId = eventIdValue is String ? eventIdValue : null;
    final notificationId =
        (message.messageId?.hashCode ?? eventId?.hashCode ?? 0) & 0x7fffffff;

    await _plugin.show(
      notificationId,
      notification.title ?? 'Eventify Campus',
      notification.body ?? '',
      const NotificationDetails(
        android: _eventChannel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: eventId == null ? null : 'event_approved:$eventId',
    );
  }

  // =============================================
  // SCHEDULED REMINDER NOTIFICATIONS
  // =============================================

  /// Replace the configurable deadline reminders for an event.
  Future<void> scheduleEventReminders(EventModel event) async {
    if (!_canUsePlugin) return;
    await cancelEventReminders(event.id);
    if (event.status != 'Aktif') return;

    final selectedDays = event.reminderDaysBefore.toSet();
    for (final daysBefore in EventModel.supportedReminderDays) {
      if (!selectedDays.contains(daysBefore)) continue;

      final reminderDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day - daysBefore,
        event.date.hour,
        event.date.minute,
      );
      if (!reminderDate.isAfter(DateTime.now())) continue;

      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local);
      final deadlineText = DateFormat('dd MMM yyyy, HH:mm').format(event.date);
      await _plugin.zonedSchedule(
        _reminderNotificationId(event.id, daysBefore),
        daysBefore == 0
            ? '⏰ Deadline Hari Ini'
            : '⏰ Deadline $daysBefore Hari Lagi',
        '${event.name}\nDeadline: $deadlineText',
        scheduledDate,
        const NotificationDetails(
          android: _reminderChannel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: _scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'event_deadline:${event.id}:$daysBefore',
      );

      if (kDebugMode) {
        print(
          '[NotificationService] Deadline reminder scheduled for: ${event.name} at $scheduledDate',
        );
      }
    }
  }

  /// Preserve the existing one-hour event-start notification.
  Future<void> scheduleEventReminderHourBefore(EventModel event) async {
    if (!_canUsePlugin) return;
    final reminderTime = event.date.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      event.id.hashCode + 6000,
      '🔔 Event Dimulai 1 Jam Lagi!',
      '${event.name}\n📍 ${event.location}',
      scheduledDate,
      const NotificationDetails(
        android: _reminderChannel,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'event_reminder_hour:${event.id}',
    );
  }

  /// Cancel all reminders for a specific event
  Future<void> cancelEventReminders(String eventId) async {
    if (!_canUsePlugin) return;
    for (final daysBefore in EventModel.supportedReminderDays) {
      await _plugin.cancel(_reminderNotificationId(eventId, daysBefore));
    }
    final pendingNotifications = await _plugin.pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      final payload = notification.payload;
      if (payload == 'event_reminder:$eventId' ||
          payload == 'event_reminder_hour:$eventId' ||
          payload?.startsWith('event_deadline:$eventId:') == true) {
        await _plugin.cancel(notification.id);
      }
    }
    // Cancel reminder IDs created by the previous one-day reminder implementation.
    await _plugin.cancel(eventId.hashCode + 5000);
    await _plugin.cancel(eventId.hashCode + 6000);
  }

  int _reminderNotificationId(String eventId, int daysBefore) {
    var hash = 0x811c9dc5;
    for (final codeUnit in eventId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    final reminderIndex = EventModel.supportedReminderDays.indexOf(daysBefore);
    return (hash * EventModel.supportedReminderDays.length + reminderIndex) &
        0x7fffffff;
  }

  AndroidScheduleMode get _scheduleMode => _canScheduleExactNotifications
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (!_canUsePlugin) return;
    await _plugin.cancelAll();
  }

  /// Get list of pending (scheduled) notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_canUsePlugin) return const [];
    return await _plugin.pendingNotificationRequests();
  }
}
