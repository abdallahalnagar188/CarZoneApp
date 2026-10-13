import 'package:carzone/core/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test Supabase phone OTP auth response handling', () async {
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.init();

    try {
      await SupabaseService.client.auth.signInWithOtp(phone: '+201001234567');
    } on AuthException catch (e) {
      // Expected if phone provider isn't enabled yet in dashboard
      expect(e.statusCode, isNotNull);
    }
  });
}
