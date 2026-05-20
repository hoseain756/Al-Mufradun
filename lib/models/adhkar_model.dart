class AdhkarModel {
  /// Stable ID assigned from the item's index in the JSON array.
  /// Format: "adhkar_<index>" — survives data reordering via migration.
  final String id;

  final String category;
  final String count;
  final String description;
  final String reference;
  final String zekr;
  final String font;
  final String share;

  AdhkarModel({
    required this.id,
    required this.category,
    required this.count,
    required this.description,
    required this.reference,
    required this.zekr,
    this.font = '',
    this.share = '',
  });

  /// Creates an AdhkarModel from a JSON map with an externally assigned [index].
  ///
  /// Validates that required fields are present and non-empty strings.
  /// Throws [FormatException] if `zekr` (the core content) is missing or empty.
  factory AdhkarModel.fromJson(Map<String, dynamic> json, {required int index}) {
    final zekr = _parseString(json, 'zekr');
    if (zekr.isEmpty) {
      throw FormatException(
        'Invalid adhkar entry at index $index: "zekr" field is missing or empty.',
      );
    }

    final category = _parseString(json, 'category');
    if (category.isEmpty) {
      throw FormatException(
        'Invalid adhkar entry at index $index: "category" field is missing or empty.',
      );
    }

    return AdhkarModel(
      id: 'adhkar_$index',
      category: category,
      count: _parseString(json, 'count', fallback: '1'),
      description: _parseString(json, 'description'),
      reference: _parseString(json, 'reference'),
      zekr: zekr,
      font: _parseString(json, 'font'),
      share: _parseString(json, 'share'),
    );
  }

  /// Safely extracts a trimmed string from [json], returning [fallback] if
  /// the key is absent, null, or not a String.
  static String _parseString(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value is String) return value.trim();
    return fallback;
  }

  /// Whether this verse should use the UthmanicHafs Quranic font.
  bool get isQuranicFont => font == 'UthmanicHafs';

  /// Text to use when sharing/copying. Uses `share` field if available, otherwise `zekr`.
  String get shareText => share.isNotEmpty ? share : zekr;

  /// The repetition count parsed as an integer. Defaults to 1.
  int get countInt => int.tryParse(count) ?? 1;

  /// Legacy ID based on zekr hashCode, used only for favorites migration.
  String get _legacyId => zekr.hashCode.toString();

  /// Builds a migration map from legacy hashCode-based IDs to stable IDs.
  /// Used once during the first launch after the ID scheme change.
  static Map<String, String> buildMigrationMap(List<AdhkarModel> items) {
    final map = <String, String>{};
    for (final item in items) {
      map[item._legacyId] = item.id;
    }
    return map;
  }
}
