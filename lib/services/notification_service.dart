import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'timezone_service.dart';

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

  // ── Android notification channels ───────────────────────
  static const int _androidPrayerChannelSchemaVersion = 3;
  static const String _androidPrayerChannelSchemaPrefKey =
      'android_prayer_notification_channel_schema_version';

  static const String _channelIdStandard = 'prayer_reminders_standard_adhan_v3';
  static const String _channelIdFajr = 'prayer_reminders_fajr_adhan_v3';

  static const String _channelNameStandard = 'تنبيهات الصلاة';
  static const String _channelNameFajr = 'تنبيهات صلاة الفجر';

  static const String _channelDescStandard = 'تنبيهات لأوقات الصلوات الأربع الأخرى';
  static const String _channelDescFajr = 'تنبيهات لوقت صلاة الفجر';

  /// Initialize the notification plugin with Android & iOS settings.
  Future<void> init() async {
    if (_initialized) return;

    await TimezoneService.configureLocalTimeZone();

    // Android initialization: use the app icon as the notification icon
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Permission prompts are requested explicitly from app-driven flows. Keeping
    // init quiet allows background schedule refreshes to run safely.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await _configureAndroidPrayerChannels(androidPlugin);
    }

    _initialized = true;
  }

  Future<void> _configureAndroidPrayerChannels(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSchemaVersion =
        prefs.getInt(_androidPrayerChannelSchemaPrefKey) ?? 0;

    if (savedSchemaVersion != _androidPrayerChannelSchemaVersion) {
      await _deletePrayerNotificationChannels(androidPlugin);
    }

    // Android raw resource sounds must be referenced by resource entry name
    // only. Do not include ".mp3" here.
    const androidChannelStandard = AndroidNotificationChannel(
      _channelIdStandard,
      _channelNameStandard,
      description: _channelDescStandard,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('y1000'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );

    const androidChannelFajr = AndroidNotificationChannel(
      _channelIdFajr,
      _channelNameFajr,
      description: _channelDescFajr,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('y1001'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(androidChannelStandard);
    await androidPlugin.createNotificationChannel(androidChannelFajr);

    await prefs.setInt(
      _androidPrayerChannelSchemaPrefKey,
      _androidPrayerChannelSchemaVersion,
    );
  }

  Future<void> _deletePrayerNotificationChannels(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    const prayerChannelIds = <String>[
      'prayer_reminders',
      'prayer_reminders_standard',
      'prayer_reminders_fajr',
      'prayer_reminders_standard_adhan',
      'prayer_reminders_fajr_adhan',
      'prayer_reminders_standard_adhan_v1',
      'prayer_reminders_fajr_adhan_v1',
      'prayer_reminders_standard_adhan_v2',
      'prayer_reminders_fajr_adhan_v2',
      'prayer_reminders_standard_adhan_v3',
      'prayer_reminders_fajr_adhan_v3',
    ];

    for (final channelId in prayerChannelIds) {
      await androidPlugin.deleteNotificationChannel(channelId: channelId);
    }
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

    final isFajr = (id ~/ 100) == 1;
    final channelId = isFajr ? _channelIdFajr : _channelIdStandard;
    final channelName = isFajr ? _channelNameFajr : _channelNameStandard;
    final channelDesc = isFajr ? _channelDescFajr : _channelDescStandard;
    final androidSoundName = isFajr ? 'y1001' : 'y1000';
    final iosSoundName = isFajr ? 'y1001.mp3' : 'y1000.mp3';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max, // ✅ Set to MAX
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(androidSoundName),
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: const BigTextStyleInformation(''),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: iosSoundName, // ✅ Custom sound
    );

    final details = NotificationDetails(
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

  /// Cancel all rolling prayer notifications owned by the prayer scheduler.
  Future<void> cancelScheduledPrayerNotifications({
    required int scheduledWindowDays,
  }) async {
    final ids = <int>{
      ...prayerNotificationIds.values,
      for (final prayerId in prayerNotificationIds.values)
        for (var offset = 0; offset < scheduledWindowDays; offset++)
          (prayerId * 100) + offset,
    };

    await Future.wait(ids.map((id) => _plugin.cancel(id: id)));
    debugPrint('🚫 Cancelled ${ids.length} prayer notifications');
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🚫 Cancelled all notifications');
  }
}
