import 'dart:io';

import 'package:carzone/commons/models/branch_listing_model.dart';
import 'package:carzone/commons/models/branch_model.dart';
import 'package:carzone/commons/models/localized_text.dart';
import 'package:carzone/commons/widgets/cards/wash_card.dart';
import 'package:carzone/core/constance/app_colors.dart';
import 'package:carzone/core/constance/supabase_constants.dart';
import 'package:carzone/core/local/cache_controller.dart';
import 'package:carzone/core/local/cache_helper.dart';
import 'package:carzone/core/network/dio_helper.dart';
import 'package:carzone/core/services/carzone_db_service.dart';
import 'package:carzone/core/services/session_service.dart';
import 'package:carzone/features/favorites/presentaion/controllers/favorites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final dummyBranch = BranchModel(
    id: 'br_test_favorite',
    businessId: 'biz_1',
    name: const LocalizedText('مغسلة التجربة', 'Test Wash'),
    areaId: 'nasr',
    address: const LocalizedText('شارع النصر', 'Nasr St'),
    lat: 30.05,
    lng: 31.35,
    phone: '0100000000',
    amenities: const [],
    capacity: 4,
    workingHours: const [],
    photoSeed: 1,
  );

  final dummyRow = BranchListingModel(
    branch: dummyBranch,
    km: 1.2,
    rating: 4.8,
    reviewCount: 42,
    fromPrice: 150,
    open: true,
    nextSlot: null,
  );

  testWidgets('WashCard renders red heart when favorite is true', (tester) async {
    var favoriteTapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: WashCard(
              row: dummyRow,
              favorite: true,
              onFavorite: () {
                favoriteTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify filled heart icon is rendered with red color
    final iconFinder = find.byIcon(Iconsax.heart5);
    expect(iconFinder, findsOneWidget);

    final iconWidget = tester.widget<Icon>(iconFinder);
    expect(iconWidget.color, equals(Colors.red));

    // Tap the favorite button
    await tester.tap(iconFinder);
    await tester.pumpAndSettle();
    expect(favoriteTapped, isTrue);
  });

  testWidgets('WashCard renders outlined dark heart when favorite is false', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: WashCard(
              row: dummyRow,
              favorite: false,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final iconFinder = find.byIcon(Iconsax.heart);
    expect(iconFinder, findsOneWidget);

    final iconWidget = tester.widget<Icon>(iconFinder);
    expect(iconWidget.color, equals(AppColors.ink900));
  });

  test('FavoritesController toggles favorite locally and dispatches to Supabase', () async {
    final db = Get.put(CarzoneDbService());
    Get.put(SessionService());
    final favController = Get.put(FavoritesController());

    const testBranchId = 'br_test_toggle';
    expect(favController.isFavorite(testBranchId), isFalse);

    // Toggle on
    favController.toggle(testBranchId);
    expect(favController.isFavorite(testBranchId), isTrue);
    expect(db.favorites.contains(testBranchId), isTrue);

    // Toggle off
    favController.toggle(testBranchId);
    expect(favController.isFavorite(testBranchId), isFalse);
    expect(db.favorites.contains(testBranchId), isFalse);
  });
}
