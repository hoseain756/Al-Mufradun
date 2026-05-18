class AdhkarModel {
  final String category;
  final String count;
  final String description;
  final String reference;
  final String zekr;
  final String font;
  final String share;

  AdhkarModel({
    required this.category,
    required this.count,
    required this.description,
    required this.reference,
    required this.zekr,
    this.font = '',
    this.share = '',
  });

  factory AdhkarModel.fromJson(Map<String, dynamic> json) {
    return AdhkarModel(
      category: json['category'] ?? '',
      count: json['count'] ?? '',
      description: json['description'] ?? '',
      reference: json['reference'] ?? '',
      zekr: json['zekr'] ?? '',
      font: json['font'] ?? '',
      share: json['share'] ?? '',
    );
  }

  /// Whether this verse should use the UthmanicHafs Quranic font.
  bool get isQuranicFont => font == 'UthmanicHafs';

  /// Text to use when sharing/copying. Uses `share` field if available, otherwise `zekr`.
  String get shareText => share.isNotEmpty ? share : zekr;

  String get id => zekr.hashCode.toString();
}
