import 'app_translation.dart';

class AppTranslationsBridge {
  AppTranslationsBridge._();

  static String currentLanguage = 'ar';
  static final Map<String, Map<String, String>> _keys = AppTranslations().keys;

  static String get(String key) {
    final langMap = _keys[currentLanguage] ?? _keys['ar'] ?? const {};
    return langMap[key] ?? key;
  }

  static String getWithParams(String key, Map<String, String> params) {
    String text = get(key);
    for (final entry in params.entries) {
      text = text.replaceAll('@${entry.key}', entry.value);
    }
    return text;
  }
}

extension AppTranslationExtension on String {
  String get tr => AppTranslationsBridge.get(this);
  String trParams([Map<String, String> params = const {}]) =>
      AppTranslationsBridge.getWithParams(this, params);
}
