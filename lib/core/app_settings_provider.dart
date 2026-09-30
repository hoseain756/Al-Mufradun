import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application-wide user preferences: theme mode, adhkar font size and the
/// onboarding flag. Deliberately free of any feature business logic.
class AppSettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode'; // 'system' | 'light' | 'dark'
  static const String _legacyIsDarkKey = 'isDark'; // old boolean key
  static const String _fontSizeKey = 'fontSize';
  static const String _onboardingCompletedKey = 'onboardingCompleted';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;
  bool _onboardingCompleted = false;

  Timer? _saveDebounceTimer;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get onboardingCompleted => _onboardingCompleted;

  AppSettingsProvider() {
    _loadPreferences();
  }

  // ── Theme ────────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _debouncedSave();
    notifyListeners();
  }

  // ── Font size ────────────────────────────────────────────

  void adjustFontSize(double delta) {
    final newSize = (_fontSize + delta).clamp(14.0, 32.0);
    if (_fontSize == newSize) return;
    _fontSize = newSize;
    _debouncedSave();
    notifyListeners();
  }

  // ── Onboarding ───────────────────────────────────────────

  void completeOnboarding() {
    if (_onboardingCompleted) return;
    _onboardingCompleted = true;
    _savePreferences();
    notifyListeners();
  }

  // ── Persistence ──────────────────────────────────────────

  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _savePreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeStr = prefs.getString(_themeModeKey);
    if (themeModeStr != null) {
      _themeMode = _themeModeFromString(themeModeStr);
    } else {
      // Migrate from legacy isDark boolean
      final isDark = prefs.getBool(_legacyIsDarkKey);
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        await prefs.setString(
          _themeModeKey,
          _themeModeToString(_themeMode),
        );
        await prefs.remove(_legacyIsDarkKey);
      }
      // If neither exists, keep default ThemeMode.system
    }

    _fontSize = prefs.getDouble(_fontSizeKey) ?? 18.0;
    _onboardingCompleted =
        prefs.getBool(_onboardingCompletedKey) ?? false;

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      _themeModeToString(_themeMode),
    );
    await prefs.setDouble(_fontSizeKey, _fontSize);
    await prefs.setBool(_onboardingCompletedKey, _onboardingCompleted);
  }

  // ── ThemeMode serialization helpers ──────────────────────

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    // Flush any pending save before disposal
    _savePreferences();
    super.dispose();
  }
}
