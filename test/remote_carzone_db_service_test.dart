import 'dart:io';

import 'package:carzone/core/constance/supabase_constants.dart';
import 'package:carzone/core/enums/enums.dart';
import 'package:carzone/core/local/cache_controller.dart';
import 'package:carzone/core/local/cache_helper.dart';
import 'package:carzone/core/network/dio_helper.dart';
import 'package:carzone/core/services/carzone_db_service.dart';
import 'package:carzone/core/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carzone/commons/models/customer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _RealHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await CacheController().initSharedPreferences();
    await CacheHelper.init();
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      publishableKey: SupabaseConstants.supabaseAnonKey,
    );
    await DioHelper.init();
  });

  tearDown(() {
    Get.reset();
  });

  test('CarzoneDbService loads 100% remote data from Supabase without dummy data', () async {
    final db = Get.put(CarzoneDbService());

    // Initially all collections should be empty (no mock seeding)
    expect(db.areas.isEmpty, isTrue);
    expect(db.branches.isEmpty, isTrue);
    expect(db.services.isEmpty, isTrue);
    expect(db.offers.isEmpty, isTrue);

    // Verify safe area fallback when empty
    final fallbackArea = db.area('any_id');
    expect(fallbackArea.id, equals('nasr'));
    expect(fallbackArea.lat, equals(30.0566));

    // Fetch from Supabase (Home essentials)
    final success = await db.fetchHomeData();
    expect(success, isTrue);
    expect(db.isSynced.value, isTrue);
    expect(db.hasError.value, isFalse);

    // Verify remote master collections are populated with home limits
    expect(db.areas.length, greaterThanOrEqualTo(8));
    expect(db.branches.length, greaterThanOrEqualTo(1));
    expect(db.offers.length, greaterThanOrEqualTo(1));

    // Test on-demand branch details fetch
    final nasrBranch = await db.fetchBranchDetails('br_nasr');
    expect(nasrBranch, isNotNull);
    expect(nasrBranch!.name.ar, contains('كارزن'));

    final nasrServices = db.servicesFor('br_nasr');
    expect(nasrServices, isNotEmpty);

    // Test on-demand pagination
    final paged = await db.fetchPaginatedBranches(page: 0, pageSize: 5);
    expect(paged.length, greaterThan(0));
    expect(paged.length, lessThanOrEqualTo(5));

    // Order numbers and check-in codes are assigned by the server (create_order).
    final ticket = db.nextTicket();
    expect(ticket.startsWith('TK-'), isTrue);
  });

  test('SessionService token lifecycle: save, cache, access, and clear', () async {
    final db = Get.put(CarzoneDbService());
    await db.fetchHomeData();

    final session = Get.put(SessionService().init());
    const testToken = 'test_jwt_access_token_xyz_123';

    // 1. Initially token is null
    expect(session.accessToken, isNull);

    // 2. Save token
    await session.saveToken(testToken);

    // Verify in-memory access token
    expect(session.accessToken, equals(testToken));
    expect(session.userToken.value, equals(testToken));

    // Verify cached in CacheController and CacheHelper
    expect(CacheController().getter(key: CacheKeys.userToken), equals(testToken));

    // Verify DioHelper Authorization header is updated
    expect(DioHelper.dio.options.headers['Authorization'], equals('Bearer $testToken'));

    // 3. Clear token
    await session.clearToken();

    // Verify in-memory is cleared
    expect(session.accessToken, isNull);
    expect(session.userToken.value, isNull);
    expect(CacheController().getter(key: CacheKeys.userToken), isNull);

    // Verify DioHelper Authorization header reverted to publishable key
    expect(
      DioHelper.dio.options.headers['Authorization'],
      equals('Bearer ${SupabaseConstants.supabasePublishableKey}'),
    );
  });

  test('CustomerModel token serialization and Supabase DB token update', () async {
    final db = Get.put(CarzoneDbService());
    await db.fetchHomeData();

    // Add a test customer to test token update
    final testCust = CustomerModel(
      id: 'test_cust_token',
      name: 'Test Customer',
      phone: '+201000000000',
    );
    db.customers.add(testCust);

    const sampleToken = 'sample_db_token_999';

    // Update customer token in local DB
    await db.updateCustomerToken(testCust.id, sampleToken);

    // Verify local model updated
    final updated = db.customerById(testCust.id);
    expect(updated?.accessToken, equals(sampleToken));
    expect(updated?.tokenUpdatedAt, isNotNull);

    // Verify toLocalJson includes access_token
    final json = updated!.toLocalJson();
    expect(json['access_token'], equals(sampleToken));

    // Clear customer token
    await db.updateCustomerToken(testCust.id, null);
    expect(db.customerById(testCust.id)?.accessToken, isNull);
  });
}
