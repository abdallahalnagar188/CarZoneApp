import 'package:carzone/core/supabase_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase integration test: connect and query app_health', () async {
    final client = SupabaseClient(
      SupabaseConstants.supabaseUrl,
      SupabaseConstants.supabaseAnonKey,
    );

    // 1. Verify client is initialized
    expect(client, isNotNull);

    // 2. Query app_health table
    final data = await client
        .from('app_health')
        .select()
        .eq('service_name', 'CarZone Mobile App');

    // 3. Verify data response
    expect(data, isNotEmpty);
    expect(data.first['service_name'], equals('CarZone Mobile App'));
    expect(data.first['status'], equals('connected'));
  });
}
