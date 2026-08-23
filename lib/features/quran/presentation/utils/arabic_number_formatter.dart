class ArabicNumberFormatter {
  ArabicNumberFormatter._();

  static const List<String> _digits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  static String format(int value) {
    return value
        .toString()
        .split('')
        .map((digit) => _digits[int.parse(digit)])
        .join();
  }
}
