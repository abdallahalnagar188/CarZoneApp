import 'package:shared_preferences/shared_preferences.dart';

import '../enums/enums.dart';

class CacheController {
  static final CacheController _instance = CacheController._internal();
  factory CacheController() => _instance;
  CacheController._internal();

  late SharedPreferences _shared;
  bool _cacheInitialized = false;

  Future<void> initSharedPreferences() async {
    _shared = await SharedPreferences.getInstance();
    _cacheInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_cacheInitialized) await initSharedPreferences();
  }

  Future<void> setter({required CacheKeys key, required dynamic value}) async {
    await _ensureInitialized();
    if (value is String) {
      await _shared.setString(key.name, value);
    } else if (value is int) {
      await _shared.setInt(key.name, value);
    } else if (value is bool) {
      await _shared.setBool(key.name, value);
    } else if (value is List<String>) {
      await _shared.setStringList(key.name, value);
    }
  }

  dynamic getter({required CacheKeys key}) {
    if (!_cacheInitialized) return null;
    return _shared.get(key.name);
  }

  Future<void> logout() async {
    await _ensureInitialized();
    for (final key in [
      CacheKeys.loggedIn,
      CacheKeys.userId,
      CacheKeys.userToken,
      CacheKeys.name,
      CacheKeys.mobile,
    ]) {
      await _shared.remove(key.name);
    }
  }
}
