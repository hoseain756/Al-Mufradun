import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adhkar_model.dart';

class AppProvider with ChangeNotifier {
  List<AdhkarModel> _adhkarList = [];
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 18.0;

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;

  AppProvider() {
    _loadPreferences();
    loadAdhkarData();
  }

  Future<void> loadAdhkarData() async {
    try {
      final String response = await rootBundle.loadString('assets/adhkar.json');
      final List<dynamic> data = json.decode(response);
      _adhkarList = data.map((json) => AdhkarModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading adhkar data: $e');
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    _savePreferences();
    notifyListeners();
  }

  void adjustFontSize(double delta) {
    _fontSize = (_fontSize + delta).clamp(14.0, 32.0);
    _savePreferences();
    notifyListeners();
  }

  Set<String> _favoriteIds = {};

  List<AdhkarModel> get favoriteAdhkarList {
    return _adhkarList.where((item) => _favoriteIds.contains(item.id)).toList();
  }

  bool isFavorite(AdhkarModel item) => _favoriteIds.contains(item.id);

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
    await prefs.setStringList('favoriteIds', _favoriteIds.toList());
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    _fontSize = prefs.getDouble('fontSize') ?? 18.0;
    _favoriteIds = (prefs.getStringList('favoriteIds') ?? []).toSet();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode != ThemeMode.system) {
      await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    }
    await prefs.setDouble('fontSize', _fontSize);
  }
}
