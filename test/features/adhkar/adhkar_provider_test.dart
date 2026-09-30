import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adhkar_viewer/features/adhkar/adhkar_provider.dart';
import 'package:adhkar_viewer/features/adhkar/models/adhkar_model.dart';

AdhkarModel _item(int index, {String category = 'cat', int count = 3}) {
  return AdhkarModel.fromJson({
    'zekr': 'zekr $index',
    'category': category,
    'count': '$count',
  }, index: index);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdhkarProvider dhikr counter', () {
    test('increments up to target and never exceeds it', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      final item = _item(0);
      expect(provider.getDhikrCount(item.id), 0);

      provider.incrementDhikrCount(item.id, target: 3);
      provider.incrementDhikrCount(item.id, target: 3);
      final last = provider.incrementDhikrCount(item.id, target: 3);

      expect(last, 3);
      expect(
        provider.incrementDhikrCount(item.id, target: 3),
        3, // already completed
      );
      expect(provider.isDhikrCompleted(item), isTrue);
    });

    test('resets daily counts when the calendar day changes', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final ymd =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({
        'dhikrCounts': json.encode({'adhkar_0': 3}),
        'dhikrCountsDate': ymd,
      });

      final provider = AdhkarProvider();
      await provider.initialized;

      expect(provider.getDhikrCount('adhkar_0'), 0); // stale -> cleared
    });

    test('persists counts through the debounce window', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      provider.incrementDhikrCount('adhkar_1', target: 5);
      await Future<void>.delayed(const Duration(milliseconds: 600));

      final prefs = await SharedPreferences.getInstance();
      final stored = json.decode(prefs.getString('dhikrCounts')!);
      expect(stored['adhkar_1'], 1);
    });

    test('resetDhikrCount and resetAllDhikrCounts clear state', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      provider.incrementDhikrCount('adhkar_0', target: 9);
      provider.incrementDhikrCount('adhkar_1', target: 9);
      provider.resetDhikrCount('adhkar_0');
      expect(provider.getDhikrCount('adhkar_0'), 0);
      expect(provider.getDhikrCount('adhkar_1'), 1);

      provider.resetAllDhikrCounts();
      expect(provider.getDhikrCount('adhkar_1'), 0);
    });
  });

  group('AdhkarProvider favorites', () {
    test('toggleFavorite adds then removes and persists', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      final loaded = provider.adhkarList.first;
      provider.toggleFavorite(loaded);
      expect(provider.isFavorite(loaded), isTrue);
      expect(
        provider.favoriteAdhkarList.map((e) => e.id),
        contains(loaded.id),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      provider.toggleFavorite(loaded);
      expect(provider.isFavorite(loaded), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('favoriteIds'), isEmpty);
    });

    test('loads favorites from prefs into state', () async {
      SharedPreferences.setMockInitialValues({
        'favoriteIds': ['adhkar_3'],
        'favoritesMigrated_v2': true,
      });

      final provider = AdhkarProvider();
      await provider.initialized;

      final item = _item(3);
      expect(provider.isFavorite(item), isTrue);
    });
  });

  group('AdhkarProvider search', () {
    test('setSearchQuery filters filteredAdhkarList', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      final needle = provider.adhkarList.first.zekr.substring(0, 3);
      provider.setSearchQuery('  $needle  ');
      expect(provider.searchQuery, needle);
      expect(provider.filteredAdhkarList, isNotEmpty);
      expect(
        provider.filteredAdhkarList
            .every((e) => '${e.category} ${e.description} ${e.zekr}'
                .toLowerCase()
                .contains(needle.toLowerCase())),
        isTrue,
      );

      provider.clearSearch();
      provider.clearSearch(); // idempotent
      expect(provider.searchQuery, '');
      expect(provider.filteredAdhkarList, provider.adhkarList);
    });
  });

  group('AdhkarProvider categories & progress', () {
    test('exposes unique categories in data order', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      final categories = provider.categories;
      expect(categories.length, categories.toSet().length);
      expect(categories, isNotEmpty);
    });

    test('category progress reaches 1.0 when every dhikr is completed',
        () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      final category = provider.categories.first;
      final items = provider.getAdhkarByCategory(category);
      // Skip categories with a target of 1 per item — complete everything.
      for (final item in items) {
        while (!provider.isDhikrCompleted(item)) {
          provider.incrementDhikrCount(item.id, target: item.countInt);
        }
      }

      expect(provider.getCategoryProgress(category), 1.0);
    });
  });

  group('AdhkarProvider data loading', () {
    test('loads bundled adhkar.json successfully', () async {
      final provider = AdhkarProvider();
      await provider.initialized;

      expect(provider.isLoading, isFalse);
      expect(provider.loadError, isNull);
      expect(provider.adhkarList, isNotEmpty);
      expect(provider.isDataReady, isTrue);
    });
  });
}
