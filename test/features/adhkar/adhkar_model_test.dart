import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar_viewer/features/adhkar/models/adhkar_model.dart';

void main() {
  group('AdhkarModel.fromJson', () {
    test('parses a valid entry and assigns stable index-based id', () {
      final model = AdhkarModel.fromJson({
        'zekr': 'سبحان الله',
        'category': 'أذكار الصباح',
        'count': '3',
        'description': 'وصف',
        'reference': 'مصدر',
        'font': 'UthmanicHafs',
        'share': 'نص المشاركة',
      }, index: 5);

      expect(model.id, 'adhkar_5');
      expect(model.zekr, 'سبحان الله');
      expect(model.category, 'أذكار الصباح');
      expect(model.countInt, 3);
      expect(model.isQuranicFont, isTrue);
      expect(model.shareText, 'نص المشاركة');
    });

    test('throws FormatException when zekr is missing or empty', () {
      expect(
        () => AdhkarModel.fromJson({'category': 'x'}, index: 0),
        throwsFormatException,
      );
      expect(
        () => AdhkarModel.fromJson({'zekr': '   ', 'category': 'x'}, index: 0),
        throwsFormatException,
      );
    });

    test('throws FormatException when category is missing or empty', () {
      expect(
        () => AdhkarModel.fromJson({'zekr': 'x'}, index: 0),
        throwsFormatException,
      );
      expect(
        () => AdhkarModel.fromJson({'zekr': 'x', 'category': ''}, index: 0),
        throwsFormatException,
      );
    });

    test('non-string and absent optional fields fall back safely', () {
      final model = AdhkarModel.fromJson({
        'zekr': 'ذكر',
        'category': 'cat',
        'count': 33, // wrong type -> fallback '1'
      }, index: 1);

      expect(model.countInt, 1);
      expect(model.description, '');
      expect(model.reference, '');
      expect(model.font, '');
      expect(model.isQuranicFont, isFalse);
      expect(model.shareText, model.zekr);
    });

    test('shareText prefers share field over zekr', () {
      final model = AdhkarModel.fromJson({
        'zekr': 'zekr text',
        'category': 'cat',
        'share': 'share text',
      }, index: 0);

      expect(model.shareText, 'share text');
    });

    test('buildMigrationMap maps legacy hashCode ids to stable ids', () {
      final a = AdhkarModel.fromJson({'zekr': 'a', 'category': 'c'}, index: 0);
      final b = AdhkarModel.fromJson({'zekr': 'b', 'category': 'c'}, index: 7);
      final map = AdhkarModel.buildMigrationMap([a, b]);

      expect(map[a.zekr.hashCode.toString()], 'adhkar_0');
      expect(map[b.zekr.hashCode.toString()], 'adhkar_7');
      expect(map.length, 2);
    });
  });
}
