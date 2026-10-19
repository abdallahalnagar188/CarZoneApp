import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../commons/models/customer_model.dart';
import '../../../../core/constance/supabase_constants.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/supabase_service.dart';

/// The phone number is already linked to a different account (sync_customer_profile).
class PhoneInUseException implements Exception {}

class AuthRepo {
  SupabaseClient get _client => SupabaseService.client;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  /// Send a phone OTP via Supabase Auth.
  /// Phone must be in E.164 format, e.g. +201001234567
  Future<String?> sendOtp(String e164Phone) async {
    try {
      await _client.auth.signInWithOtp(phone: e164Phone);
      return null; // success
    } on AuthException catch (e) {
      dev.log('[AuthRepo] sendOtp error: ${e.message} (status: ${e.statusCode})');
      return mapAuthError(e);
    } catch (e) {
      dev.log('[AuthRepo] sendOtp unexpected error: $e');
      return mapAuthError(e);
    }
  }

  /// Verify the OTP code the user entered.
  /// Returns null on success, or an error key on failure.
  Future<String?> verifyOtp(String e164Phone, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        phone: e164Phone,
        token: code,
        type: OtpType.sms,
      );
      if (response.session == null) {
        return 'otp.invalid'.tr;
      }
      return null; // success — session is now active
    } on AuthException catch (e) {
      dev.log('[AuthRepo] verifyOtp error: ${e.message}');
      return mapAuthError(e, isVerify: true);
    } catch (e) {
      dev.log('[AuthRepo] verifyOtp unexpected error: $e');
      return mapAuthError(e, isVerify: true);
    }
  }

  /// Map raw backend exceptions (Twilio 20003, sms_send_failed, network errors)
  /// to clean, user-friendly localized messages without exposing internal URLs or technical errors.
  String mapAuthError(dynamic error, {bool isVerify = false}) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = (error.statusCode ?? '').toLowerCase();

      // Twilio / SMS provider failures (e.g. 20003, sms_send_failed, invalid credentials)
      if (msg.contains('twilio') ||
          msg.contains('20003') ||
          msg.contains('sms_send_failed') ||
          msg.contains('provider') ||
          msg.contains('otp to provider') ||
          msg.contains('invalid username')) {
        return 'login.sms_error'.tr;
      }

      // Rate limiting / Too many requests
      if (msg.contains('rate limit') ||
          msg.contains('too many') ||
          msg.contains('over_sms_send_rate_limit')) {
        return 'login.rate_limit'.tr;
      }

      // Expired OTP
      if (msg.contains('expired')) {
        return 'otp.expired'.tr;
      }

      // Invalid token or code
      if (msg.contains('token') ||
          msg.contains('invalid') ||
          msg.contains('incorrect') ||
          msg.contains('wrong') ||
          (code == '400' && isVerify)) {
        return 'otp.invalid'.tr;
      }

      if (isVerify) {
        return 'otp.invalid'.tr;
      }
      return 'login.sms_error'.tr;
    }

    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('connection') ||
        str.contains('failed host lookup') ||
        str.contains('clientexception')) {
      return 'offline.action'.tr;
    }

    return isVerify ? 'otp.error'.tr : 'login.sms_error'.tr;
  }

  /// Find an existing customer in the local DB or Supabase by phone number.
  Future<CustomerModel?> findCustomerByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final local = _db.customers.firstWhereOrNull(
      (c) => c.phone == cleanPhone || c.phone == phone,
    );
    if (local != null) return local;
    try {
      final res = await _client
          .from('customers')
          .select()
          .eq('phone', cleanPhone)
          .maybeSingle();
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } catch (e) {
      dev.log('[AuthRepo] findCustomerByPhone error: $e');
    }
    return null;
  }

  /// Find an existing customer by their Supabase auth UID.
  Future<CustomerModel?> findCustomerByAuthId(String authId) async {
    final local = _db.customers.firstWhereOrNull(
      (c) => c.userId == authId || c.id == authId,
    );
    if (local != null) return local;
    try {
      final res = await _client
          .from('customers')
          .select()
          .eq('user_id', authId)
          .maybeSingle();
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } catch (e) {
      dev.log('[AuthRepo] findCustomerByAuthId error: $e');
    }
    return null;
  }

  /// Atomically sync/find/create customer profile using Postgres RPC.
  /// The server links an existing customer only through the OTP-verified phone.
  /// Throws [PhoneInUseException] when the number belongs to another account.
  Future<CustomerModel?> syncProfile({
    required String phone,
    String? name,
    String? locale,
    String? token,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(' ', '');
      final effectiveToken = token ?? _client.auth.currentSession?.accessToken;
      final res = await _client.rpc('sync_customer_profile', params: {
        'p_phone': cleanPhone,
        if (name != null) 'p_name': name.trim(),
        'p_locale': locale ?? (Get.locale?.languageCode ?? 'ar'),
      });
      if (res != null) {
        final map = Map<String, dynamic>.from(res as Map);
        final cust = CustomerModel.fromJson(map);
        cust.accessToken = effectiveToken;
        cust.tokenUpdatedAt = effectiveToken != null ? DateTime.now() : null;

        final idx = _db.customers.indexWhere((c) => c.id == cust.id || (cust.userId != null && c.userId == cust.userId));
        if (idx != -1) {
          _db.customers[idx] = cust;
        } else {
          _db.customers.add(cust);
        }
        return cust;
      }
    } on PostgrestException catch (e) {
      dev.log('[AuthRepo] syncProfile refused: ${e.message}');
      if (e.message == 'phone_in_use') throw PhoneInUseException();
    } catch (e) {
      dev.log('[AuthRepo] syncProfile error: $e');
    }
    return null;
  }

  /// Register a new customer through sync_customer_profile (the only way to
  /// create one). Throws [PhoneInUseException] or [StateError] on failure,
  /// never returns a local-only customer.
  Future<CustomerModel> register(
      String authId, String phone, String name, {String? token}) async {
    final synced = await syncProfile(
      phone: phone.replaceAll(' ', ''),
      name: name,
      token: token ?? _client.auth.currentSession?.accessToken,
    );
    if (synced == null) {
      throw StateError('sync_customer_profile returned no customer for $authId');
    }
    return synced;
  }

  /// Sign out of Supabase Auth.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      dev.log('[AuthRepo] signOut error: $e');
    }
  }

  /// Native in-app Google Sign-In with bottom sheet account picker dialog.
  /// Does NOT open external Chrome browser.
  Future<AuthResponse?> signInWithGoogleNative({String? webClientId}) async {
    final effectiveServerClientId = webClientId ??
        (SupabaseConstants.googleWebClientId.isNotEmpty
            ? SupabaseConstants.googleWebClientId
            : null);

    final effectiveClientId = SupabaseConstants.googleAndroidClientId.isNotEmpty
        ? SupabaseConstants.googleAndroidClientId
        : null;

    final googleSignIn = GoogleSignIn(
      clientId: effectiveClientId,
      serverClientId: effectiveServerClientId,
    );

    // Sign out first so the native account picker dialog appears every time
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // User canceled or dismissed the popup dialog
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      dev.log('[AuthRepo] idToken is null. Check if googleWebClientId is configured.');
      throw const AuthException('تعذر الحصول على رمز التحقق من Google. يرجى التأكد من إضافة Web Client ID.');
    }

    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    return res;
  }

  /// In-app browser view OAuth fallback (opens in-app modal instead of separate Chrome app)
  Future<bool> signInWithGoogleInAppBrowser() async {
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'carzone://login-callback',
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return res;
    } on AuthException catch (e) {
      dev.log('[AuthRepo] signInWithGoogleInAppBrowser AuthException: ${e.message}');
      return false;
    } catch (e) {
      dev.log('[AuthRepo] signInWithGoogleInAppBrowser unexpected error: $e');
      return false;
    }
  }

  /// Get the current auth user (if any).
  User? get currentAuthUser => _client.auth.currentUser;

  /// Get the current auth session access token (if any).
  String? get currentSessionToken => _client.auth.currentSession?.accessToken;
}
