import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adhkar_model.dart';

/// Keys used for SharedPreferences storage. Centralised to prevent typos.
class _PrefKeys {
  static const String themeMode = 'themeMode'; // 'system' | 'light' | 'dark'
  static const String legacyIsDark = 'isDark'; // old boolean key
  static const String fontSize = 'fontSize';
  static const String favoriteIds = 'favoriteIds';
  static const String favoritesMigrated = 'favoritesMigrated_v2';
  static const String onboardingCompleted = 'onboardingCompleted';
  static const String dhikrCounts = 'dhikrCounts';
  static const String dhikrCountsDate = 'dhikrCountsDate';
}

class AppProvider with ChangeNotifier {
  // ── Adhkar data ──────────────────────────────────────────
  List<AdhkarModel> _adhkarList = [];
  bool _isLoading = true;
  String? _loadError;

  // ── Theme ────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.system;

  // ── Font size ────────────────────────────────────────────
  double _fontSize = 18.0;

  // ── Search ───────────────────────────────────────────────
  String _searchQuery = '';

  // ── Favorites ────────────────────────────────────────────
  Set<String> _favoriteIds = {};

  // ── Dhikr counter (daily reset) ──────────────────────────
  Map<String, int> _dhikrCounts = {};
  String _dhikrCountsDate = '';

  // ── Onboarding ───────────────────────────────────────────
  bool _onboardingCompleted = false;

  // ── Save debouncing ──────────────────────────────────────
  Timer? _saveDebounceTimer;

  // ═══════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════

  List<AdhkarModel> get adhkarList => _adhkarList;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isDataReady => _adhkarList.isNotEmpty && !_isLoading;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  String get searchQuery => _searchQuery;
  bool get onboardingCompleted => _onboardingCompleted;

  List<String> get categories {
    final ids = <String>{};
    final list = <String>[];
    for (var item in _adhkarList) {
      if (!ids.contains(item.category) && item.category.isNotEmpty) {
        ids.add(item.category);
        list.add(item.category);
      }
    }
    return list;
  }

  List<AdhkarModel> getAdhkarByCategory(String category) {
    return _adhkarList.where((item) => item.category == category).toList();
  }

  List<AdhkarModel> get filteredAdhkarList {
    if (_searchQuery.isEmpty) return _adhkarList;
    final q = _searchQuery.toLowerCase();
    return _adhkarList.where((item) {
      final text =
          '${item.category} ${item.description} ${item.zekr}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  List<AdhkarModel> get favoriteAdhkarList {
    return _adhkarList.where((item) => _favoriteIds.contains(item.id)).toList();
  }

  bool isFavorite(AdhkarModel item) => _favoriteIds.contains(item.id);

  // ── Dhikr counter getters ────────────────────────────────

  /// Current count for a given adhkar ID. Returns 0 if not started.
  int getDhikrCount(String adhkarId) => _dhikrCounts[adhkarId] ?? 0;

  /// Progress as a fraction (0.0 to 1.0) for a given adhkar item.
  /// Returns 1.0 if targetCount is 0 or count >= target.
  double getDhikrProgress(AdhkarModel item) {
    final target = item.countInt;
    if (target <= 0) return 1.0;
    final current = getDhikrCount(item.id);
    return (current / target).clamp(0.0, 1.0);
  }

  /// Whether this adhkar's dhikr count has reached its target.
  bool isDhikrCompleted(AdhkarModel item) {
    return getDhikrCount(item.id) >= item.countInt;
  }

  // ── Category progress ────────────────────────────────────

  /// Returns a progress fraction (0.0 to 1.0) representing how many adhkar
  /// in [category] have been fully completed today.
  double getCategoryProgress(String category) {
    final items = getAdhkarByCategory(category);
    if (items.isEmpty) return 0.0;
    final completedCount = items.where((item) => isDhikrCompleted(item)).length;
    return completedCount / items.length;
  }

  // ═══════════════════════════════════════════════════════════
  // Constructor & Initialization
  // ═══════════════════════════════════════════════════════════

  /// Completer exposed so the splash screen can await data readiness.
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initialized => _initCompleter.future;

  AppProvider() {
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    try {
      // Load preferences first so theme is applied before data
      await _loadPreferences();
      await loadAdhkarData();
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Data Loading (Change 3: loading/error state)
  // ═══════════════════════════════════════════════════════════

  Future<void> loadAdhkarData() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final String response =
          await rootBundle.loadString('assets/adhkar.json');
      final dynamic decoded = json.decode(response);

      if (decoded is! List) {
        throw FormatException(
          'Expected a JSON array at root, got ${decoded.runtimeType}.',
        );
      }

      final List<AdhkarModel> parsed = [];
      final List<String> parseErrors = [];

      for (int i = 0; i < decoded.length; i++) {
        final entry = decoded[i];
        if (entry is! Map<String, dynamic>) {
          parseErrors.add('Entry at index $i is not a JSON object.');
          continue;
        }
        try {
          parsed.add(AdhkarModel.fromJson(entry, index: i));
        } on FormatException catch (e) {
          parseErrors.add(e.message);
          // Skip malformed entries rather than crashing the entire load
        }
      }

      if (parsed.isEmpty) {
        throw FormatException(
          'No valid adhkar entries found. Errors: ${parseErrors.join('; ')}',
        );
      }

      if (parseErrors.isNotEmpty) {
        debugPrint(
          'Warning: ${parseErrors.length} adhkar entries skipped: '
          '${parseErrors.take(5).join('; ')}',
        );
      }

      _adhkarList = parsed;

      // Run favorites migration if not done yet
      await _migrateFavoritesIfNeeded();

      _isLoading = false;
      _loadError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading adhkar data: $e');
      _isLoading = false;
      _loadError = 'فشل تحميل البيانات. يرجى إعادة تشغيل التطبيق.';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Favorites Migration (Change 1: hashCode -> stable IDs)
  // ═══════════════════════════════════════════════════════════

  Future<void> _migrateFavoritesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_PrefKeys.favoritesMigrated) ?? false) return;
    if (_favoriteIds.isEmpty) {
      // Nothing to migrate; mark done
      await prefs.setBool(_PrefKeys.favoritesMigrated, true);
      return;
    }

    final migrationMap = AdhkarModel.buildMigrationMap(_adhkarList);
    final migratedIds = <String>{};
    var migrationCount = 0;

    for (final oldId in _favoriteIds) {
      if (oldId.startsWith('adhkar_')) {
        // Already in new format
        migratedIds.add(oldId);
      } else if (migrationMap.containsKey(oldId)) {
        migratedIds.add(migrationMap[oldId]!);
        migrationCount++;
      }
      // If an old ID has no match, it is silently dropped (data was removed)
    }

    _favoriteIds = migratedIds;
    await prefs.setStringList(_PrefKeys.favoriteIds, _favoriteIds.toList());
    await prefs.setBool(_PrefKeys.favoritesMigrated, true);

    if (migrationCount > 0) {
      debugPrint('Migrated $migrationCount favorite IDs to stable format.');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Search (Change 9: safe to call at any time)
  // ═══════════════════════════════════════════════════════════

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return; // No-op avoids redundant rebuilds
    _searchQuery = trimmed;
    notifyListeners();
  }

  /// Convenience method for clearing search. Safe to call repeatedly.
  void clearSearch() => setSearchQuery('');

  // ═══════════════════════════════════════════════════════════
  // Theme (Change 4: ThemeMode enum with system support)
  // ═══════════════════════════════════════════════════════════

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _debouncedSave();
    notifyListeners();
  }

  /// Legacy toggle cycles: system -> light -> dark -> system
  void cycleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Font Size
  // ═══════════════════════════════════════════════════════════

  void adjustFontSize(double delta) {
    final newSize = (_fontSize + delta).clamp(14.0, 32.0);
    if (_fontSize == newSize) return;
    _fontSize = newSize;
    _debouncedSave();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // Favorites
  // ═══════════════════════════════════════════════════════════

  void toggleFavorite(AdhkarModel item) {
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
    } else {
      _favoriteIds.add(item.id);
    }
    _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_PrefKeys.favoriteIds, _favoriteIds.toList());
  }

  // ═══════════════════════════════════════════════════════════
  // Dhikr Counter (Change 2: daily counter state)
  // ═══════════════════════════════════════════════════════════

  /// Increment the dhikr count for an adhkar item.
  /// Returns the new count. Does not exceed the target count.
  int incrementDhikrCount(String adhkarId, {int target = 1}) {
    _ensureDhikrCountsForToday();
    final current = _dhikrCounts[adhkarId] ?? 0;
    if (current >= target) return current; // Already completed
    _dhikrCounts[adhkarId] = current + 1;
    _debouncedSaveDhikrCounts();
    notifyListeners();
    return current + 1;
  }

  /// Reset dhikr count for a single adhkar item.
  void resetDhikrCount(String adhkarId) {
    _ensureDhikrCountsForToday();
    if (!_dhikrCounts.containsKey(adhkarId)) return;
    _dhikrCounts.remove(adhkarId);
    _debouncedSaveDhikrCounts();
    notifyListeners();
  }

  /// Reset all dhikr counts (manual full reset).
  void resetAllDhikrCounts() {
    _dhikrCounts.clear();
    _dhikrCountsDate = _todayDateString();
    _saveDhikrCounts();
    notifyListeners();
  }

  /// Checks if we are still on the same calendar day. If the day has changed,
  /// clears all counts automatically (daily reset).
  void _ensureDhikrCountsForToday() {
    final today = _todayDateString();
    if (_dhikrCountsDate != today) {
      _dhikrCounts.clear();
      _dhikrCountsDate = today;
    }
  }

  static String _todayDateString() {
    final now = DateTime.now();
    // yyyy-MM-dd format without importing intl just for this
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Timer? _dhikrSaveTimer;

  void _debouncedSaveDhikrCounts() {
    _dhikrSaveTimer?.cancel();
    _dhikrSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDhikrCounts();
    });
  }

  Future<void> _saveDhikrCounts() async {
    final prefs = await SharedPreferences.getInstance();
    // Encode counts as JSON string: {"adhkar_0": 3, "adhkar_5": 1, ...}
    await prefs.setString(
      _PrefKeys.dhikrCounts,
      json.encode(_dhikrCounts),
    );
    await prefs.setString(_PrefKeys.dhikrCountsDate, _dhikrCountsDate);
  }

  Future<void> _loadDhikrCounts(SharedPreferences prefs) async {
    _dhikrCountsDate = prefs.getString(_PrefKeys.dhikrCountsDate) ?? '';
    final today = _todayDateString();

    if (_dhikrCountsDate != today) {
      // Stale data from a previous day — start fresh
      _dhikrCounts = {};
      _dhikrCountsDate = today;
      return;
    }

    final raw = prefs.getString(_PrefKeys.dhikrCounts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          _dhikrCounts = decoded.map(
            (key, value) => MapEntry(key, value is int ? value : 0),
          );
        }
      } catch (_) {
        _dhikrCounts = {};
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Onboarding (Change 8)
  // ═══════════════════════════════════════════════════════════

  void completeOnboarding() {
    if (_onboardingCompleted) return;
    _onboardingCompleted = true;
    _saveOnboarding();
    notifyListeners();
  }

  Future<void> _saveOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.onboardingCompleted, true);
  }

  // ═══════════════════════════════════════════════════════════
  // Preferences Persistence (with debounced saves)
  // ═══════════════════════════════════════════════════════════

  void _debouncedSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _savePreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Theme mode (Change 4: migrate from isDark boolean) ──
    final themeModeStr = prefs.getString(_PrefKeys.themeMode);
    if (themeModeStr != null) {
      _themeMode = _themeModeFromString(themeModeStr);
    } else {
      // Migrate from legacy isDark boolean
      final isDark = prefs.getBool(_PrefKeys.legacyIsDark);
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        // Persist in new format and clean up old key
        await prefs.setString(_PrefKeys.themeMode, _themeModeToString(_themeMode));
        await prefs.remove(_PrefKeys.legacyIsDark);
      }
      // If neither exists, keep default ThemeMode.system
    }

    _fontSize = prefs.getDouble(_PrefKeys.fontSize) ?? 18.0;
    _favoriteIds = (prefs.getStringList(_PrefKeys.favoriteIds) ?? []).toSet();
    _onboardingCompleted =
        prefs.getBool(_PrefKeys.onboardingCompleted) ?? false;

    await _loadDhikrCounts(prefs);

    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _PrefKeys.themeMode, _themeModeToString(_themeMode));
    await prefs.setDouble(_PrefKeys.fontSize, _fontSize);
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

  // ═══════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _dhikrSaveTimer?.cancel();
    // Flush any pending saves before disposal
    _savePreferences();
    _saveDhikrCounts();
    super.dispose();
  }
}
