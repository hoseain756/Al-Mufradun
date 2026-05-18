import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for managing local prayer-time notifications.
///
/// Handles initialization, permission requests, scheduling daily
/// repeating notifications, and cancellation.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Whether the service has been initialized.
  bool _initialized = false;

  // ── Notification IDs for each prayer ──────────────────────
  static const Map<String, int> prayerNotificationIds = {
    'fajr': 1,
    'dhuhr': 2,
    'asr': 3,
    'maghrib': 4,
    'isha': 5,
  };

  // ── Android notification channel ─────────────────────────
  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'تنبيهات الصلاة';
  static const String _channelDesc = 'تنبيهات لأوقات الصلوات الخمس';

  /// Initialize the notification plugin with Android & iOS settings.
  Future<void> init() async {
    if (_initialized) return;

    // Android initialization: use the app icon as the notification icon
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS initialization: request alert, badge, sound
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Create the Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max, // ✅ Set to MAX as requested
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'), // ✅ Custom sound
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Request notification permission (Android 13+ / iOS).
  Future<bool> requestPermission() async {
    // Try Android-specific permission request first
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      // ✅ Request standard notification permission
      final granted = await androidImpl.requestNotificationsPermission();

      // ✅ Request exact alarm permission (Android 12+)
      final exactAlarmGranted =
          await androidImpl.requestExactAlarmsPermission();
      debugPrint('🔔 Exact alarm permission granted: $exactAlarmGranted');

      return granted ?? false;
    }

    // iOS permission request
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // other platforms — assume granted
  }

  /// Schedule a one-shot notification at the exact supplied [prayerTime].
  Future<bool> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime prayerTime,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = prayerTime is tz.TZDateTime
        ? prayerTime
        : tz.TZDateTime.from(prayerTime, tz.local);

    if (!scheduledDate.isAfter(now)) {
      debugPrint('⏩ Skipping past notification #$id at: $scheduledDate');
      return false;
    }

    // ── Debug Logs ───────────────────────────────────────────
    debugPrint('🕒 Scheduled $title notification at: $scheduledDate');
    debugPrint('⌚ Current time: $now');
    debugPrint('⌛ Difference: ${scheduledDate.difference(now)}');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max, // ✅ Set to MAX
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'), // ✅ Custom sound
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'adhan.mp3', // ✅ Custom sound
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint('⚠️ Exact alarm failed for #$id, using inexact schedule: $e');
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    return true;
  }

  /// Cancel a specific prayer notification by its [id].
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
    debugPrint('🚫 Cancelled notification #$id');
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🚫 Cancelled all notifications');
  }
}
