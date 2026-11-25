// GAP-070: the access token is never copied into plain SharedPreferences.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/core/local/cache_controller.dart';
import 'package:washup/core/local/cache_helper.dart';
import 'package:washup/core/services/session_service.dart';

import 'qa_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await CacheController().initSharedPreferences();
    await CacheHelper.init();
  });

  tearDown(Get.reset);

  test('saving the session token keeps it out of SharedPreferences', () async {
    freshDb();
    final session = Get.put(SessionService());
    await session.saveToken('eyJ.test.token');
    expect(session.accessToken, 'eyJ.test.token');
    expect(CacheController().getter(key: CacheKeys.userToken), isNull);
  });
}
