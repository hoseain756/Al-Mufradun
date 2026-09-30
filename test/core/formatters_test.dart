import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar_viewer/core/utils/arabic_number_formatter.dart';
import 'package:adhkar_viewer/features/prayer_times/utils/arabic_time_formatter.dart';

void main() {
  group('ArabicNumberFormatter', () {
    test('formats western digits as Arabic-Indic digits', () {
      expect(ArabicNumberFormatter.format(0), '٠');
      expect(ArabicNumberFormatter.format(9), '٩');
      expect(ArabicNumberFormatter.format(123), '١٢٣');
      expect(ArabicNumberFormatter.format(604), '٦٠٤');
    });
  });

  group('ArabicTimeFormatter', () {
    test('formats morning time with ص suffix', () {
      final time = DateTime(2026, 1, 1, 8, 30);
      final result = ArabicTimeFormatter.formatTime(time);
      expect(result, contains('08:30'));
      expect(result, endsWith('ص'));
    });

    test('formats afternoon time with م suffix', () {
      final time = DateTime(2026, 1, 1, 16, 45);
      final result = ArabicTimeFormatter.formatTime(time);
      expect(result, contains('04:45'));
      expect(result, endsWith('م'));
    });
  });
}
