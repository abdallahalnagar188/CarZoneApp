import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/enums.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;
  static late FlutterSecureStorage _secureStorage;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
  }

  static Future<void> clearCache({required String key}) async {
    await sharedPreferences.remove(key);
    await _secureStorage.delete(key: key);
  }

  static Future<void> assignSecureData({
    required String key,
    required String value,
  }) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> safeRead({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Secure storage read error for key [$key]: $e');
      await _secureStorage.delete(key: key);
      return null;
    }
  }

  static Future<bool> assignData({
    required String key,
    required String value,
  }) {
    return sharedPreferences.setString(key, value);
  }

  static Future<bool> assignBoolData({
    required String key,
    required bool value,
  }) {
    return sharedPreferences.setBool(key, value);
  }

  static Future<bool> assignListData({
    required String key,
    required List<String> value,
  }) {
    return sharedPreferences.setStringList(key, value);
  }

  static dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  static List<String> getList({required String key}) {
    return sharedPreferences.getStringList(key) ?? const [];
  }

  static bool get isLoggedIn {
    return sharedPreferences.getBool(CacheKeys.loggedIn.name) ?? false;
  }

  static bool get isOnboarded {
    return sharedPreferences.getBool(CacheKeys.onboarded.name) ?? false;
  }
}
