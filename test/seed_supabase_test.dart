import 'package:carzone/core/constance/supabase_constants.dart';
import 'package:carzone/core/services/carzone_db_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Seed Supabase database with all mock data', () async {
    final client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );

    final db = CarzoneDbService().init();

    // 1. Areas
    final areaData = db.areas.map((a) => a.toJson()).toList();
    await client.from('areas').upsert(areaData, onConflict: 'id');

    // 2. Branches
    final branchData = db.branches.map((b) => b.toJson()).toList();
    await client.from('branches').upsert(branchData, onConflict: 'id');

    // 3. Services
    final serviceData = db.services.map((s) => s.toJson()).toList();
    await client.from('services').upsert(serviceData, onConflict: 'id');

    // 4. Offers
    final offerData = db.offers.map((o) => o.toJson()).toList();
    await client.from('offers').upsert(offerData, onConflict: 'id');

    // 5. Customers
    final customerData = db.customers.map((c) => c.toJson()).toList();
    await client.from('customers').upsert(customerData, onConflict: 'id');

    // 6. Vehicles
    final vehicleData = db.vehicles.map((v) => v.toJson()).toList();
    await client.from('vehicles').upsert(vehicleData, onConflict: 'id');

    // 7. Orders
    final orderData = db.orders.map((o) => o.toJson()).toList();
    await client.from('orders').upsert(orderData, onConflict: 'id');

    // 8. Reviews
    final reviewData = db.reviews.map((r) => r.toJson()).toList();
    await client.from('reviews').upsert(reviewData, onConflict: 'id');

    // 9. Notifications
    final notifData = db.notifications.map((n) => n.toJson()).toList();
    await client.from('notifications').upsert(notifData, onConflict: 'id');

    expect(true, isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
