import 'package:get/get.dart';

class LocalizedText {
  final String ar;
  final String en;

  const LocalizedText(this.ar, this.en);

  String get value => (Get.locale?.languageCode ?? 'ar') == 'ar' ? ar : en;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return ar.toLowerCase().contains(q) || en.toLowerCase().contains(q);
  }

  factory LocalizedText.fromJson(dynamic json) {
    if (json is Map) {
      return LocalizedText(
        json['ar']?.toString() ?? '',
        json['en']?.toString() ?? '',
      );
    }
    final text = json?.toString() ?? '';
    return LocalizedText(text, text);
  }

  Map<String, dynamic> toJson() => {'ar': ar, 'en': en};

  @override
  String toString() => value;
}
