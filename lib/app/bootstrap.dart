import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import '../features/prayer_times/services/notification_service.dart';
import '../features/prayer_times/services/prayer_scheduler.dart';
import '../features/prayer_times/services/timezone_service.dart';

const String prayerRefreshTaskName = 'refreshPrayerSchedule';
const String prayerRefreshUniqueName = 'com.hussein.almufradun.prayer.refresh';

@pragma('vm:entry-point')
void prayerRefreshCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    await TimezoneService.configureLocalTimeZone();
    await NotificationService.instance.init();

    PrayerScheduler.instance.attachMethodChannelHandler();
    await PrayerScheduler.instance.refreshSchedule(requestPermissions: false);

    return true;
  });
}

Future<void> _configurePrayerBackgroundRefresh() async {
  await Workmanager().initialize(prayerRefreshCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    prayerRefreshUniqueName,
    prayerRefreshTaskName,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

/// Initialise timezone, notifications, method-channel bridges and WorkManager.
///
/// Called once by the splash screen after it is already visible on-screen,
/// guaranteeing no race between services and consumers like
/// [PrayerTimeProvider].
Future<void> initializeAppServices() async {
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure local timezone correctly before anything that needs tz.local.
  await TimezoneService.configureLocalTimeZone();

  // Initialize the notification service singleton
  await NotificationService.instance.init();
  PrayerScheduler.instance.attachMethodChannelHandler();

  // Keep prayer notification schedules refreshed while the app is closed.
  await _configurePrayerBackgroundRefresh();
}
