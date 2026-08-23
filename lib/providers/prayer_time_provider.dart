import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/prayer_scheduler.dart';
import '../utils/arabic_time_formatter.dart';

class PrayerTimeProvider with ChangeNotifier {
  static const List<PrayerInfo> prayers = PrayerScheduler.prayers;

  final Map<String, bool> _toggleStates = {
    for (final prayer in PrayerScheduler.prayers) prayer.key: true,
  };

  final Map<String, DateTime?> _prayerTimes = {
    for (final prayer in PrayerScheduler.prayers) prayer.key: null,
  };

  bool _isLoading = true;
  String? _errorMessage;
  Coordinates? _lastCoordinates;
  CalculationParameters? _lastCalculationParams;
  tz.Location? _lastTimezoneLocation;

  bool isEnabled(String key) => _toggleStates[key] ?? false;
  DateTime? getPrayerTime(String key) => _prayerTimes[key];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get areAllPrayersEnabled =>
      prayers.every((prayer) => _toggleStates[prayer.key] == true);

  String? getFormattedTime(String key) {
    final time = _prayerTimes[key];
    if (time == null) return null;
    return ArabicTimeFormatter.formatTime(time);
  }

  String? get nextPrayerKey {
    if (_prayerTimes.values.every((time) => time == null)) return null;

    final now = _lastTimezoneLocation == null
        ? DateTime.now()
        : tz.TZDateTime.now(_lastTimezoneLocation!);
    for (final prayer in prayers) {
      final time = _prayerTimes[prayer.key];
      if (time != null && time.isAfter(now)) return prayer.key;
    }

    return 'fajr';
  }

  String? get nextPrayerNameAr {
    final key = nextPrayerKey;
    if (key == null) return null;
    return prayers.firstWhere((prayer) => prayer.key == key).nameAr;
  }

  Duration? get timeUntilNextPrayer {
    final key = nextPrayerKey;
    if (key == null) return null;

    final now = _lastTimezoneLocation == null
        ? DateTime.now()
        : tz.TZDateTime.now(_lastTimezoneLocation!);
    final todayTime = _prayerTimes[key];
    if (todayTime != null && todayTime.isAfter(now)) {
      return todayTime.difference(now);
    }

    if (_lastCoordinates != null &&
        _lastCalculationParams != null &&
        _lastTimezoneLocation != null) {
      final tomorrow = tz.TZDateTime.now(
        _lastTimezoneLocation!,
      ).add(const Duration(days: 1));
      final tomorrowTimes = PrayerTimes(
        _lastCoordinates!,
        DateComponents.from(tomorrow),
        _lastCalculationParams!,
        utcOffset: tomorrow.timeZoneOffset,
      );
      final tomorrowFajr = tz.TZDateTime(
        _lastTimezoneLocation!,
        tomorrowTimes.fajr.year,
        tomorrowTimes.fajr.month,
        tomorrowTimes.fajr.day,
        tomorrowTimes.fajr.hour,
        tomorrowTimes.fajr.minute,
        tomorrowTimes.fajr.second,
      );
      return tomorrowFajr.difference(now);
    }

    return null;
  }

  PrayerTimeProvider({bool autoInitialize = true}) {
    if (autoInitialize) {
      _initialize();
    }
  }

  /// Public entry point for deferred initialisation.
  ///
  /// Call this after timezone, notifications and other platform services are
  /// fully initialised (e.g. from [SplashScreen]).
  Future<void> startFetching() => _initialize();

  Future<void> _initialize() async {
    await _loadToggleStates();
    await _fetchAndCalculate();
  }

  Future<void> _loadToggleStates({bool notify = true}) async {
    final enabledStates =
        await PrayerScheduler.instance.loadPrayerEnabledStates();
    _toggleStates
      ..clear()
      ..addAll(enabledStates);

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
      final snapshot = await PrayerScheduler.instance.calculateToday(
        requestPermissions: requestPermissions,
      );

      _lastCoordinates = snapshot.coordinates;
      _lastCalculationParams = snapshot.calculationParameters;
      _lastTimezoneLocation = snapshot.timezoneLocation;

      for (final entry in snapshot.todayPrayerTimes.entries) {
        _prayerTimes[entry.key] = entry.value;
      }

      await PrayerScheduler.instance.refreshSchedule(
        requestPermissions: requestPermissions,
      );

      _isLoading = false;
      _errorMessage = null;
      if (notify) notifyListeners();
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
      _errorMessage = 'حدث خطأ أثناء حساب أوقات الصلاة.';
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<DateTime?> togglePrayer(String key, bool enabled) async {
    _toggleStates[key] = enabled;
    notifyListeners();

    await PrayerScheduler.instance.setPrayerEnabled(key, enabled);

    final prayerTime = _prayerTimes[key];
    if (!enabled || prayerTime == null) return null;

    final now = _lastTimezoneLocation == null
        ? DateTime.now()
        : tz.TZDateTime.now(_lastTimezoneLocation!);
    var firstScheduled = prayerTime;
    if (!firstScheduled.isAfter(now)) {
      firstScheduled = firstScheduled.add(const Duration(days: 1));
    }

    return firstScheduled;
  }

  Future<void> toggleAllPrayers(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final writes = <Future<bool>>[];

    for (final prayer in prayers) {
      _toggleStates[prayer.key] = enabled;
      writes.add(prefs.setBool('prayer_${prayer.key}', enabled));
    }

    notifyListeners();
    await Future.wait(writes);
    await PrayerScheduler.instance.refreshSchedule();
  }

  Future<void> retry() async {
    await _fetchAndCalculate();
  }

  Future<void> refreshPrayerScheduleInBackground() async {
    await _loadToggleStates(notify: false);
    await _fetchAndCalculate(requestPermissions: false, notify: false);
  }
}
