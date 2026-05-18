import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/notification_service.dart';

/// Data class representing a single prayer with its metadata.
class PrayerInfo {
  final String key; // e.g. 'fajr'
  final String nameAr; // e.g. 'الفجر'
  final String nameEn; // e.g. 'Fajr'
  final int notificationId; // base ID (1–5)

  const PrayerInfo({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.notificationId,
  });
}

enum PrayerScheduleRange {
  week('week', 'أسبوع', 7),
  month('month', 'شهر', 30),
  unlimited('unlimited', 'مطلق (لا محدود)', 365);

  final String storageKey;
  final String labelAr;
  final int days;

  const PrayerScheduleRange(this.storageKey, this.labelAr, this.days);

  static PrayerScheduleRange fromStorageKey(String? key) {
    return PrayerScheduleRange.values.firstWhere(
      (range) => range.storageKey == key,
      orElse: () => PrayerScheduleRange.month,
    );
  }
}

/// Provider for prayer time calculation, toggle state, and notification scheduling.
class PrayerTimeProvider with ChangeNotifier {
  static const int _maxCancelableScheduleDays = 365;

  // ── Static prayer definitions ────────────────────────────
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

  // ── State ────────────────────────────────────────────────
  final Map<String, bool> _toggleStates = {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false,
  };

  final Map<String, DateTime?> _prayerTimes = {
    'fajr': null,
    'dhuhr': null,
    'asr': null,
    'maghrib': null,
    'isha': null,
  };

  bool _isLoading = true;
  String? _errorMessage;
  Coordinates? _lastCoordinates;
  CalculationParameters? _lastCalculationParams;
  PrayerScheduleRange _scheduleRange = PrayerScheduleRange.month;

  // ── Getters ──────────────────────────────────────────────
  bool isEnabled(String key) => _toggleStates[key] ?? false;
  DateTime? getPrayerTime(String key) => _prayerTimes[key];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PrayerScheduleRange get scheduleRange => _scheduleRange;
  int get scheduleDaysAhead => _scheduleRange.days;
  bool get areAllPrayersEnabled =>
      prayers.every((prayer) => _toggleStates[prayer.key] == true);

  String? getFormattedTime(String key) {
    final time = _prayerTimes[key];
    if (time == null) return null;
    return DateFormat('hh:mm a').format(time);
  }

  // ── Initialization ───────────────────────────────────────

  PrayerTimeProvider({bool autoInitialize = true}) {
    if (autoInitialize) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await _loadToggleStates();
    await _fetchAndCalculate();
  }

  Future<void> _loadToggleStates({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    _scheduleRange = PrayerScheduleRange.fromStorageKey(
      prefs.getString('prayer_schedule_range'),
    );
    for (final prayer in prayers) {
      _toggleStates[prayer.key] =
          prefs.getBool('prayer_${prayer.key}') ?? false;
    }
    if (notify) notifyListeners();
  }

  Future<void> _fetchAndCalculate({
    bool requestPermissions = true,
    bool notify = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (notify) notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'خدمات الموقع غير مفعّلة. يرجى تفعيلها.';
        _isLoading = false;
        if (notify) notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermissions) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'تم رفض إذن الموقع. يرجى السماح بالوصول.';
          _isLoading = false;
          if (notify) notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.denied) {
        _errorMessage = 'تم رفض إذن الموقع. يرجى السماح بالوصول.';
        _isLoading = false;
        if (notify) notifyListeners();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'إذن الموقع مرفوض نهائياً. يرجى تفعيله من الإعدادات.';
        _isLoading = false;
        if (notify) notifyListeners();
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 30),
        ),
      );

      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.umm_al_qura.getParameters();
      params.madhab = Madhab.shafi;
      _lastCoordinates = coordinates;
      _lastCalculationParams = params;
      final prayerTimesResult = PrayerTimes.today(coordinates, params);

      _prayerTimes['fajr'] = prayerTimesResult.fajr;
      _prayerTimes['dhuhr'] = prayerTimesResult.dhuhr;
      _prayerTimes['asr'] = prayerTimesResult.asr;
      _prayerTimes['maghrib'] = prayerTimesResult.maghrib;
      _prayerTimes['isha'] = prayerTimesResult.isha;

      if (requestPermissions) {
        await NotificationService.instance.requestPermission();
      }

      // Reschedule all enabled prayers with accurate daily prayer times.
      for (final prayer in prayers) {
        if (_toggleStates[prayer.key] == true) {
          await _scheduleNotification(prayer, coordinates, params);
        }
      }

      _isLoading = false;
      _errorMessage = null;
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching prayer times: $e');
      _errorMessage = 'حدث خطأ أثناء حساب أوقات الصلاة.';
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }

  // ── Actions ───────────────────────────────────────────────

  Future<DateTime?> togglePrayer(String key, bool enabled) async {
    _toggleStates[key] = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_$key', enabled);

    final prayer = prayers.firstWhere((p) => p.key == key);

    if (enabled && _prayerTimes[key] != null) {
      // 1. Calculate the first scheduled time for the SnackBar
      final prayerTime = _prayerTimes[key]!;
      final now = tz.TZDateTime.now(tz.local);
      var firstScheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        prayerTime.hour,
        prayerTime.minute,
      );
      if (firstScheduled.isBefore(now)) {
        firstScheduled = firstScheduled.add(const Duration(days: 1));
      }

      // 2. Schedule from the already-calculated prayer data without reloading UI.
      final coordinates = _lastCoordinates;
      final params = _lastCalculationParams;
      if (coordinates != null && params != null) {
        await NotificationService.instance.requestPermission();
        await _scheduleNotification(prayer, coordinates, params);
      }

      return firstScheduled;
    } else {
      await _cancelPrayerNotifications(prayer);
      return null;
    }
  }

  Future<void> toggleAllPrayers(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    for (final prayer in prayers) {
      _toggleStates[prayer.key] = enabled;
      await prefs.setBool('prayer_${prayer.key}', enabled);
    }
    notifyListeners();

    if (!enabled) {
      for (final prayer in prayers) {
        await _cancelPrayerNotifications(prayer);
      }
      return;
    }

    final coordinates = _lastCoordinates;
    final params = _lastCalculationParams;
    if (coordinates == null || params == null) return;

    await NotificationService.instance.requestPermission();
    for (final prayer in prayers) {
      await _scheduleNotification(prayer, coordinates, params);
    }
  }

  Future<void> setScheduleRange(PrayerScheduleRange range) async {
    if (_scheduleRange == range) return;

    _scheduleRange = range;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_schedule_range', range.storageKey);
    notifyListeners();

    final coordinates = _lastCoordinates;
    final params = _lastCalculationParams;
    if (coordinates == null || params == null) return;

    for (final prayer in prayers) {
      if (_toggleStates[prayer.key] == true) {
        await _scheduleNotification(prayer, coordinates, params);
      }
    }
  }

  Future<void> _cancelPrayerNotifications(PrayerInfo prayer) async {
    for (int i = 0; i < _maxCancelableScheduleDays; i++) {
      await NotificationService.instance.cancelNotification(
        (prayer.notificationId * 1000) + i,
      );
    }
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

  /// Schedules a rolling window of one-shot notifications.
  ///
  /// Prayer times change day by day, so each alarm must use its own date.
  Future<void> _scheduleNotification(
    PrayerInfo prayer,
    Coordinates coordinates,
    CalculationParameters params,
  ) async {
    await _cancelPrayerNotifications(prayer);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledCount = 0;

    for (int i = 0; i < scheduleDaysAhead; i++) {
      final date = now.add(Duration(days: i));
      final prayerTimes = PrayerTimes(
        coordinates,
        DateComponents.from(date),
        params,
      );
      final prayerTime = _timeForPrayer(prayerTimes, prayer.key);
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        prayerTime.hour,
        prayerTime.minute,
        prayerTime.second,
      );

      final uniqueId = (prayer.notificationId * 1000) + i;

      final scheduled =
          await NotificationService.instance.schedulePrayerNotification(
        id: uniqueId,
        title: 'حان وقت صلاة ${prayer.nameAr}',
        body:
            '${prayer.nameAr} - ${DateFormat('hh:mm a').format(scheduledDate)}',
        prayerTime: scheduledDate,
      );

      if (scheduled) scheduledCount++;
    }

    debugPrint(
      '🔔 Scheduled $scheduledCount days of ${prayer.nameEn} notifications.',
    );
  }

  Future<void> retry() async {
    await _fetchAndCalculate();
  }

  Future<void> refreshPrayerScheduleInBackground() async {
    await _loadToggleStates(notify: false);
    await _fetchAndCalculate(requestPermissions: false, notify: false);
  }
}
