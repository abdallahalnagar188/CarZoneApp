import 'dart:async';
import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show closeInAppWebView;

import '../../../../commons/models/customer_model.dart';
import '../../../../core/constance/supabase_constants.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/supabase_service.dart';

/// The phone number is already linked to a different account (sync_customer_profile).
class PhoneInUseException implements Exception {}

class AuthRepo {
  SupabaseClient get _client => SupabaseService.client;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  /// The last [sendOtp] / [verifyOtp] failed on the connection, not on the
  /// code, so it should not count as a wrong attempt.
  bool lastFailureWasNetwork = false;

  /// Send a phone OTP via Supabase Auth.
  /// Phone must be in E.164 format, e.g. +201001234567
  Future<String?> sendOtp(String e164Phone) async {
    lastFailureWasNetwork = false;
    try {
      await ApiCall.write(() => _client.auth.signInWithOtp(phone: e164Phone), tag: 'sendOtp');
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
    lastFailureWasNetwork = false;
    try {
      final response = await ApiCall.write(
        () => _client.auth.verifyOTP(
          phone: e164Phone,
          token: code,
          type: OtpType.sms,
        ),
        tag: 'verifyOtp',
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
    final failure = error is Object ? ApiException.from(error) : null;
    if (failure != null) {
      lastFailureWasNetwork = true;
      return failure.message;
    }

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
  /// Throws [ApiException] when the lookup could not reach the server, so a
  /// lost connection is not mistaken for "no such customer".
  Future<CustomerModel?> findCustomerByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final local = _db.customers.firstWhereOrNull(
      (c) => c.phone == cleanPhone || c.phone == phone,
    );
    if (local != null) return local;
    try {
      final res = await ApiCall.read(
        () => _client.from('customers').select().eq('phone', cleanPhone).maybeSingle(),
        tag: 'customer by phone',
      );
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      dev.log('[AuthRepo] findCustomerByPhone error: $e');
    }
    return null;
  }

  /// Find an existing customer by their Supabase auth UID.
  /// Throws [ApiException] when the lookup could not reach the server.
  Future<CustomerModel?> findCustomerByAuthId(String authId) async {
    final local = _db.customers.firstWhereOrNull(
      (c) => c.userId == authId || c.id == authId,
    );
    if (local != null) return local;
    try {
      final res = await ApiCall.read(
        () => _client.from('customers').select().eq('user_id', authId).maybeSingle(),
        tag: 'customer by auth id',
      );
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      dev.log('[AuthRepo] findCustomerByAuthId error: $e');
    }
    return null;
  }

  /// Atomically sync/find/create customer profile using Postgres RPC.
  /// The server links an existing customer only through the OTP-verified phone.
  /// Throws [PhoneInUseException] when the number belongs to another account,
  /// [ApiException] when the server could not be reached.
  Future<CustomerModel?> syncProfile({
    required String phone,
    String? name,
    String? locale,
    String? token,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(' ', '');
      final effectiveToken = token ?? _client.auth.currentSession?.accessToken;
      final res = await ApiCall.write(
        () => _client.rpc('sync_customer_profile', params: {
          'p_phone': cleanPhone,
          if (name != null) 'p_name': name.trim(),
          'p_locale': locale ?? (Get.locale?.languageCode ?? 'ar'),
        }),
        tag: 'sync_customer_profile',
      );
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
    } on ApiException {
      rethrow;
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

  /// Native Google Sign-In needs a web client ID everywhere, and on iOS also
  /// an iOS client ID (plus its reversed URL scheme in Info.plist).
  bool get canUseNativeGoogle =>
      SupabaseConstants.googleWebClientId.isNotEmpty &&
      (!GetPlatform.isIOS || SupabaseConstants.googleIosClientId.isNotEmpty);

  /// Native in-app Google Sign-In with bottom sheet account picker dialog.
  /// Does NOT open external Chrome browser.
  Future<AuthResponse?> signInWithGoogleNative({String? webClientId}) async {
    final effectiveServerClientId = webClientId ??
        (SupabaseConstants.googleWebClientId.isNotEmpty
            ? SupabaseConstants.googleWebClientId
            : null);

    // iOS needs its own iOS client ID: any other ID makes the Google SDK raise a
    // native exception (missing URL scheme) that kills the app. Android ignores
    // clientId when serverClientId is set, and identifies the app by package + SHA-1.
    final effectiveClientId = GetPlatform.isIOS && SupabaseConstants.googleIosClientId.isNotEmpty
        ? SupabaseConstants.googleIosClientId
        : null;

    final googleSignIn = GoogleSignIn(
      clientId: effectiveClientId,
      serverClientId: effectiveServerClientId,
    );

    // Sign out first so the native account picker dialog appears every time
    try {
      await googleSignIn.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}

    // No timeout on signIn: the account picker waits for the user.
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // User canceled or dismissed the popup dialog
      return null;
    }

    final googleAuth = await googleUser.authentication.timeout(_googleStepTimeout);
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      dev.log('[AuthRepo] idToken is null. Check if googleWebClientId is configured.');
      throw const AuthException('تعذر الحصول على رمز التحقق من Google. يرجى التأكد من إضافة Web Client ID.');
    }

    // Supabase rejects the token unless the Google provider lists this
    // platform's client ID and, on iOS, skips the nonce check (the Google iOS
    // SDK embeds a nonce it never exposes).
    final res = await _client.auth
        .signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        )
        .timeout(_googleStepTimeout);
    return res;
  }

  static const _googleStepTimeout = Duration(seconds: 20);

  /// One listener for the browser flow, however many times the user retries.
  static StreamSubscription<AuthState>? _oauthSub;

  /// In-app browser view OAuth fallback (opens in-app modal instead of separate Chrome app).
  /// Requires carzone://login-callback in Supabase Auth -> URL Configuration -> Redirect URLs.
  Future<bool> signInWithGoogleInAppBrowser() async {
    // supabase_flutter signs in from the carzone://login-callback link but leaves
    // the in-app Safari sheet open on iOS, so close it once the session arrives.
    if (GetPlatform.isIOS) {
      // A sheet left open by an earlier attempt blocks the new one from showing.
      try {
        await closeInAppWebView();
      } catch (_) {}
      await _oauthSub?.cancel();
      final sub = _client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn) {
          closeInAppWebView();
          _oauthSub?.cancel();
          _oauthSub = null;
        }
      });
      _oauthSub = sub;
      Future.delayed(const Duration(minutes: 10), () {
        sub.cancel();
        if (identical(_oauthSub, sub)) _oauthSub = null;
      });
    }
    try {
      // No timeout: on iOS the call only returns once the sheet's first page
      // loads or the user closes it.
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'carzone://login-callback',
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
        // Without this Google silently reuses the account signed in to Safari,
        // which may not be the one the user just picked.
        queryParams: const {'prompt': 'select_account'},
      );
      // When Google redirects straight back to carzone:// the in-app sheet
      // reports "failed to load" although sign-in goes on through the link,
      // so on iOS only an exception means the browser could not start.
      return GetPlatform.isIOS || res;
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
