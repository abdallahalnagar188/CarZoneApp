import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carzone/core/local/app_translation.dart';
import 'package:carzone/features/auth/data/repo/auth_repo.dart';
import 'package:carzone/features/auth/presentaion/controllers/auth_controller.dart';

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

  group('Sign in with Apple never asks for a name (App Review guideline 4)', () {
    test('recognises Apple accounts from the auth metadata', () {
      expect(AuthController.isAppleUser({'provider': 'apple', 'providers': ['apple']}), isTrue);
      expect(AuthController.isAppleUser({'provider': 'phone', 'providers': ['phone', 'apple']}), isTrue);
      expect(AuthController.isAppleUser({'provider': 'google', 'providers': ['google']}), isFalse);
      expect(AuthController.isAppleUser({'provider': 'phone'}), isFalse);
      expect(AuthController.isAppleUser(null), isFalse);
    });

    test('the default name fits the customers.name rule (2 to 80 characters)', () {
      for (final locale in ['ar', 'en']) {
        Get.locale = Locale(locale);
        final name = 'profile.defaultName'.tr;
        expect(name, isNot('profile.defaultName'));
        expect(name.length, inInclusiveRange(2, 80));
        expect('profile.setupPhone'.tr, isNot('profile.setupPhone'));
        expect('profile.setupPhoneBody'.tr, isNot('profile.setupPhoneBody'));
      }
      Get.locale = const Locale('ar');
    });
  });
}
