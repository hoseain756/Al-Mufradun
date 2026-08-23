import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart'
    as lat_lng_timezone;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  TimezoneService._();

  static bool _configured = false;
  static bool _databaseInitialized = false;

  static Future<void> configureLocalTimeZone() async {
    if (_configured) return;

    _initializeDatabase();

    try {
      final rawTimezone = await FlutterTimezone.getLocalTimezone();
      final timezoneId = _normalizeTimezoneId(rawTimezone.toString());

      tz.setLocalLocation(tz.getLocation(timezoneId));
      _configured = true;
      debugPrint('🌍 Timezone configured: $timezoneId');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      _configured = true;
      debugPrint('❌ Timezone fallback to UTC: $e');
    }
  }

  static tz.Location locationForCoordinates({
    required double latitude,
    required double longitude,
  }) {
    _initializeDatabase();

    try {
      final timezoneId = lat_lng_timezone.latLngToTimezoneString(
        latitude,
        longitude,
      );
      final location = tz.getLocation(timezoneId);
      debugPrint('🌍 GPS timezone resolved: $timezoneId');
      return location;
    } catch (e) {
      debugPrint('❌ GPS timezone fallback to tz.local: $e');
      return tz.local;
    }
  }

  static void _initializeDatabase() {
    if (_databaseInitialized) return;
    tz_data.initializeTimeZones();
    _databaseInitialized = true;
  }

  static String _normalizeTimezoneId(String value) {
    if (value.contains('(') && value.contains(',')) {
      return value
          .substring(value.indexOf('(') + 1, value.indexOf(','))
          .trim();
    }

    if (value.contains('(') && value.contains(')')) {
      return value
          .substring(value.indexOf('(') + 1, value.indexOf(')'))
          .trim();
    }

    return value.trim();
  }
}
