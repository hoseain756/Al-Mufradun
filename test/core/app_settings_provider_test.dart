import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adhkar_viewer/core/app_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettingsProvider', () {
    test('loads defaults when prefs are empty', () async {
      final provider = AppSettingsProvider();
      await pumpEventQueue();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.fontSize, 18.0);
      expect(provider.onboardingCompleted, isFalse);
    });

    test('migrates legacy isDark boolean to themeMode string', () async {
      SharedPreferences.setMockInitialValues({'isDark': true});
      final provider = AppSettingsProvider();
      await pumpEventQueue();

      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
      expect(prefs.getBool('isDark'), isNull);
    });

    test('adjustFontSize clamps between 14 and 32', () async {
      final provider = AppSettingsProvider();
      await pumpEventQueue();

      provider.adjustFontSize(-100);
      expect(provider.fontSize, 14.0);

      provider.adjustFontSize(100);
      expect(provider.fontSize, 32.0);
    });

    test('completeOnboarding persists and is idempotent', () async {
      final provider = AppSettingsProvider();
      await pumpEventQueue();

      provider.completeOnboarding();
      provider.completeOnboarding(); // second call must be a no-op
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(provider.onboardingCompleted, isTrue);
      expect(prefs.getBool('onboardingCompleted'), isTrue);
    });

    test('setThemeMode persists after debounce fires', () async {
      final provider = AppSettingsProvider();
      await pumpEventQueue();

      provider.setThemeMode(ThemeMode.light);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });
  });
}
