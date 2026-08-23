import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/arabic_time_formatter.dart';
import 'notification_service.dart';
import 'timezone_service.dart';

class PrayerInfo {
  final String key;
  final String nameAr;
  final String nameEn;
  final int notificationId;

  const PrayerInfo({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.notificationId,
  });
}

class PrayerScheduleSnapshot {
  final Coordinates coordinates;
  final CalculationParameters calculationParameters;
  final tz.Location timezoneLocation;
  final Map<String, DateTime> todayPrayerTimes;

  const PrayerScheduleSnapshot({
    required this.coordinates,
    required this.calculationParameters,
    required this.timezoneLocation,
    required this.todayPrayerTimes,
  });
}

class PrayerScheduler {
  PrayerScheduler._();

  static final PrayerScheduler instance = PrayerScheduler._();

  static const int guaranteedFutureDays = 7;
  static const int scheduledWindowDays = guaranteedFutureDays + 1;
  static const int maxPendingNotifications = scheduledWindowDays * 5;
  static const MethodChannel _channel =
      MethodChannel('com.hussein.almufradun.prayer/scheduler');
  static const Duration _postPrayerRefreshDelay = Duration(seconds: 90);

  static const String _cachedLatKey = 'prayer_cached_lat';
  static const String _cachedLngKey = 'prayer_cached_lng';
  static const String _nativeAlarmMillisKey = 'prayer_next_alarm_millis';

  static const List<PrayerInfo> prayers = [
    PrayerInfo(
      key: 'fajr',
      nameAr: 'الفجر',
      nameEn: 'Fajr',
      notificationId: 1,
    ),
    PrayerInfo(
      key: 'dhuhr',
      nameAr: 'الظهر',
      nameEn: 'Dhuhr',
      notificationId: 2,
    ),
    PrayerInfo(
      key: 'asr',
      nameAr: 'العصر',
      nameEn: 'Asr',
      notificationId: 3,
    ),
    PrayerInfo(
      key: 'maghrib',
      nameAr: 'المغرب',
      nameEn: 'Maghrib',
      notificationId: 4,
    ),
    PrayerInfo(
      key: 'isha',
      nameAr: 'العشاء',
      nameEn: 'Isha',
      notificationId: 5,
    ),
  ];

  bool _channelHandlerAttached = false;

  void attachMethodChannelHandler() {
    if (_channelHandlerAttached) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'refreshSchedule') {
        await refreshSchedule(requestPermissions: false);
        return true;
      }

      throw PlatformException(
        code: 'unknown_method',
        message: 'Unknown prayer scheduler method: ${call.method}',
      );
    });

    _channelHandlerAttached = true;
  }

  Future<void> setPrayerEnabled(String key, bool enabled) async {
    if (!prayers.any((prayer) => prayer.key == key)) {
      throw ArgumentError('Unknown prayer key: $key');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_$key', enabled);

    // Rebuild the full window after every toggle. This prevents stale IDs and
    // avoids the old per-prayer cancel loop that could leave iOS above its cap.
    await refreshSchedule();
  }

  Future<Map<String, bool>> loadPrayerEnabledStates() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final prayer in prayers)
        prayer.key: prefs.getBool('prayer_${prayer.key}') ?? true,
    };
  }

  Future<PrayerScheduleSnapshot> calculateToday({
    bool requestPermissions = true,
  }) async {
    final coordinates = await _resolveCoordinates(
      requestPermissions: requestPermissions,
    );
    final params = _calculationParameters();
    final timezoneLocation = _resolveTimezone(coordinates);
    final nowAtLocation = tz.TZDateTime.now(timezoneLocation);
    final today = PrayerTimes(
      coordinates,
      DateComponents.from(nowAtLocation),
      params,
      utcOffset: nowAtLocation.timeZoneOffset,
    );

    return PrayerScheduleSnapshot(
      coordinates: coordinates,
      calculationParameters: params,
      timezoneLocation: timezoneLocation,
      todayPrayerTimes: {
        'fajr': _wallClockInLocation(today.fajr, timezoneLocation),
        'dhuhr': _wallClockInLocation(today.dhuhr, timezoneLocation),
        'asr': _wallClockInLocation(today.asr, timezoneLocation),
        'maghrib': _wallClockInLocation(today.maghrib, timezoneLocation),
        'isha': _wallClockInLocation(today.isha, timezoneLocation),
      },
    );
  }

  Future<void> refreshSchedule({bool requestPermissions = true}) async {
    await NotificationService.instance.init();

    if (requestPermissions) {
      await NotificationService.instance.requestPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    final enabledStates = await loadPrayerEnabledStates();
    final coordinates = await _resolveCoordinates(
      requestPermissions: requestPermissions,
    );
    final params = _calculationParameters();
    final timezoneLocation = _resolveTimezone(coordinates);
    final scheduledItems = _buildRollingWindow(
      coordinates: coordinates,
      params: params,
      enabledStates: enabledStates,
      timezoneLocation: timezoneLocation,
    );

    // Clear the prayer IDs first to prevent duplicates while preserving any
    // unrelated local notifications the app may add later.
    await NotificationService.instance.cancelScheduledPrayerNotifications(
      scheduledWindowDays: scheduledWindowDays,
    );

    if (scheduledItems.isEmpty) {
      await prefs.remove(_nativeAlarmMillisKey);
      await _cancelAndroidWakeup();
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _scheduleIOSWindow(scheduledItems);
    } else {
      await _scheduleWithFlutterLocalNotifications(scheduledItems);
    }

    final nextTrigger = scheduledItems
        .map((item) => item.scheduledDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final nativeRefreshAt = nextTrigger.add(_postPrayerRefreshDelay);

    await prefs.setInt(
      _nativeAlarmMillisKey,
      nativeRefreshAt.millisecondsSinceEpoch,
    );
    await _scheduleAndroidWakeup(nativeRefreshAt);

    debugPrint(
      'PrayerScheduler refreshed ${scheduledItems.length}/'
      '$maxPendingNotifications notifications.',
    );
  }

  List<_ScheduledPrayerNotification> _buildRollingWindow({
    required Coordinates coordinates,
    required CalculationParameters params,
    required Map<String, bool> enabledStates,
    required tz.Location timezoneLocation,
  }) {
    final now = tz.TZDateTime.now(timezoneLocation);
    final items = <_ScheduledPrayerNotification>[];

    for (final prayer in prayers) {
      if (enabledStates[prayer.key] != true) continue;

      var candidateDate = now;
      var occurrenceOffset = 0;

      while (occurrenceOffset < scheduledWindowDays) {
        final prayerTimes = PrayerTimes(
          coordinates,
          DateComponents.from(candidateDate),
          params,
          utcOffset: candidateDate.timeZoneOffset,
        );
        final prayerTime = _timeForPrayer(prayerTimes, prayer.key);
        final scheduledDate = _wallClockInLocation(
          prayerTime,
          timezoneLocation,
        );

        if (scheduledDate.isAfter(now)) {
          // ID = prayerId * 100 + occurrenceOffset. With prayer IDs 1..5 and
          // offsets 0..7, IDs never collide and are identical across platforms.
          final notificationId =
              (prayer.notificationId * 100) + occurrenceOffset;
          items.add(
            _ScheduledPrayerNotification(
              id: notificationId,
              title: 'حان وقت صلاة ${prayer.nameAr}',
              body:
                  '${prayer.nameAr} - ${ArabicTimeFormatter.formatTime(scheduledDate)}',
              scheduledDate: scheduledDate,
            ),
          );
          occurrenceOffset++;
        }

        candidateDate = candidateDate.add(const Duration(days: 1));
      }
    }

    assert(items.length <= maxPendingNotifications);
    return items;
  }

  Future<void> _scheduleIOSWindow(
    List<_ScheduledPrayerNotification> items,
  ) async {
    try {
      await _channel.invokeMethod<void>('refreshIOSPrayerWindow', {
        'requests': items
            .map(
              (item) => {
                'id': item.id,
                'title': item.title,
                'body': item.body,
                'triggerAtMillis': item.scheduledDate.millisecondsSinceEpoch,
              },
            )
            .toList(growable: false),
      });
    } on MissingPluginException {
      debugPrint('iOS native scheduler unavailable; falling back to FLN.');
      await _scheduleWithFlutterLocalNotifications(items);
    } on PlatformException catch (e) {
      debugPrint('iOS native scheduler failed; falling back to FLN: $e');
      await _scheduleWithFlutterLocalNotifications(items);
    }
  }

  Future<void> _scheduleWithFlutterLocalNotifications(
    List<_ScheduledPrayerNotification> items,
  ) async {
    // One Future per notification, then a single Future.wait. No sequential
    // await in the hot scheduling path, so the UI isolate is not blocked by
    // 40 platform-channel round trips.
    await Future.wait(
      items.map(
        (item) async {
          try {
            await NotificationService.instance.schedulePrayerNotification(
              id: item.id,
              title: item.title,
              body: item.body,
              prayerTime: item.scheduledDate,
            );
          } on PlatformException catch (e) {
            // Log sound or scheduling errors but do not fail the whole refresh.
            debugPrint('⚠️ Notification scheduling failed for ${item.id}: $e');
          }
        },
      ),
    );
  }

  Future<void> _scheduleAndroidWakeup(DateTime triggerAt) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod<void>('scheduleNextExactAlarm', {
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      });
    } on MissingPluginException {
      debugPrint('Android exact alarm bridge is not available on this target.');
    } on PlatformException catch (e) {
      debugPrint('Failed to schedule Android exact wakeup: $e');
    }
  }

  Future<void> _cancelAndroidWakeup() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod<void>('cancelNextExactAlarm');
    } on MissingPluginException {
      debugPrint('Android exact alarm bridge is not available on this target.');
    } on PlatformException catch (e) {
      debugPrint('Failed to cancel Android exact wakeup: $e');
    }
  }

  Future<Coordinates> _resolveCoordinates({
    required bool requestPermissions,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _cachedCoordinatesOrThrow(prefs);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermissions) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _cachedCoordinatesOrThrow(prefs);
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 30),
        ),
      );

      await prefs.setDouble(_cachedLatKey, position.latitude);
      await prefs.setDouble(_cachedLngKey, position.longitude);
      return Coordinates(position.latitude, position.longitude);
    } on TimeoutException {
      return _cachedCoordinatesOrThrow(prefs);
    } on LocationServiceDisabledException {
      return _cachedCoordinatesOrThrow(prefs);
    } on PermissionDeniedException {
      return _cachedCoordinatesOrThrow(prefs);
    } catch (e) {
      debugPrint('Location lookup failed, trying cached coordinates: $e');
      return _cachedCoordinatesOrThrow(prefs);
    }
  }

  Coordinates _cachedCoordinatesOrThrow(SharedPreferences prefs) {
    final lat = prefs.getDouble(_cachedLatKey);
    final lng = prefs.getDouble(_cachedLngKey);

    if (lat != null && lng != null) {
      debugPrint('Using cached prayer coordinates: $lat, $lng');
      return Coordinates(lat, lng);
    }

    throw StateError('No GPS coordinates are available for prayer scheduling.');
  }

  CalculationParameters _calculationParameters() {
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    return params;
  }

  tz.Location _resolveTimezone(Coordinates coordinates) {
    return TimezoneService.locationForCoordinates(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }

  tz.TZDateTime _wallClockInLocation(DateTime time, tz.Location location) {
    return tz.TZDateTime(
      location,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }

  DateTime _timeForPrayer(PrayerTimes prayerTimes, String key) {
    switch (key) {
      case 'fajr':
        return prayerTimes.fajr;
      case 'dhuhr':
        return prayerTimes.dhuhr;
      case 'asr':
        return prayerTimes.asr;
      case 'maghrib':
        return prayerTimes.maghrib;
      case 'isha':
        return prayerTimes.isha;
      default:
        throw ArgumentError('Unknown prayer key: $key');
    }
  }
}

class _ScheduledPrayerNotification {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;

  const _ScheduledPrayerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });
}
