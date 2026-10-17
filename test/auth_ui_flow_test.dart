import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carzone/core/local/app_translation.dart';
import 'package:carzone/features/auth/data/repo/auth_repo.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('ar');
  });

  test('AuthRepo maps Twilio 20003 error to clean Arabic user message', () {
    final repo = AuthRepo();
    // Simulate Supabase Twilio 20003 AuthException
    const twilioException = AuthException(
      'Error sending confirmation OTP to provider: Authentication Error - invalid username More information: https://www.twilio.com/docs/errors/20003',
      statusCode: '500',
    );

    final mapped = repo.mapAuthError(twilioException);

    expect(mapped, isNot(contains('twilio')));
    expect(mapped, isNot(contains('20003')));
    expect(mapped, isNot(contains('http')));
    expect(mapped, contains('تعذر إرسال رمز التحقق'));
  });

  test('AuthRepo maps rate limit error cleanly without exposing technical details', () {
    final repo = AuthRepo();
    const rateLimitException = AuthException(
      'over_sms_send_rate_limit: Too many requests',
      statusCode: '429',
    );

    final mapped = repo.mapAuthError(rateLimitException);
    expect(mapped, contains('تجاوز الحد المسموح'));
  });

  test('AuthRepo maps expired OTP token to expired message', () {
    final repo = AuthRepo();
    const expiredTokenException = AuthException(
      'Token has expired or is invalid',
      statusCode: '400',
    );

    final mapped = repo.mapAuthError(expiredTokenException, isVerify: true);
    expect(mapped, contains('انتهت صلاحية رمز التحقق'));
  });

  test('AuthRepo maps wrong OTP code to invalid message', () {
    final repo = AuthRepo();
    const wrongTokenException = AuthException(
      'Invalid token',
      statusCode: '400',
    );

    final mapped = repo.mapAuthError(wrongTokenException, isVerify: true);
    expect(mapped, contains('رمز التحقق غير صحيح'));
  });
}
