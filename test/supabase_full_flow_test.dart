import 'package:carzone/core/services/carzone_db_service.dart';
import 'package:carzone/core/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Full Supabase integration and fetch test', () async {
    // Mock shared preferences for Flutter test environment
    SharedPreferences.setMockInitialValues({});

    // 1. Initialize Supabase
    await SupabaseService.init();

    // 2. Initialize DB Service
    final db = CarzoneDbService();
    
    // 3. Fetch all live data from Supabase tables
    final success = await db.fetchFromSupabase();
    expect(success, isTrue);

    // 4. Assert loaded data from Supabase
    expect(db.areas, isNotEmpty);
    expect(db.areas.length, equals(8));

    expect(db.branches, isNotEmpty);
    expect(db.branches.length, equals(13));

    expect(db.services, isNotEmpty);
    expect(db.services.length, equals(91));

    expect(db.offers, isNotEmpty);
    expect(db.offers.length, equals(3));

    expect(db.customers, isNotEmpty);
    expect(db.customers.length, greaterThanOrEqualTo(20));

    expect(db.vehicles, isNotEmpty);
    expect(db.vehicles.length, greaterThanOrEqualTo(2));

    expect(db.orders, isNotEmpty);
    expect(db.orders.length, equals(20));

    expect(db.reviews, isNotEmpty);
    expect(db.reviews.length, greaterThanOrEqualTo(100));

    expect(db.notifications, isNotEmpty);
    expect(db.notifications.length, equals(2));

    // 5. Test computed properties from live Supabase data
    final nasrRating = db.ratingFor('br_nasr');
    expect(nasrRating.count, greaterThan(0));
    expect(nasrRating.rating, greaterThan(3.5));
  });
}
