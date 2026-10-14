import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../commons/models/customer_model.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/supabase_service.dart';

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
      dev.log('[AuthRepo] sendOtp error: ${e.message}');
      return e.message;
    } catch (e) {
      dev.log('[AuthRepo] sendOtp unexpected error: $e');
      return 'otp.error'.tr;
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
      if (e.message.toLowerCase().contains('expired')) {
        return 'otp.expired'.tr;
      }
      return 'otp.invalid'.tr;
    } catch (e) {
      dev.log('[AuthRepo] verifyOtp unexpected error: $e');
      return 'otp.error'.tr;
    }
  }

  /// Find an existing customer in the local DB or Supabase by phone number.
  Future<CustomerModel?> findCustomerByPhone(String prettyPhone) async {
    final local = _db.customerByPhone(prettyPhone);
    if (local != null) return local;
    try {
      final res = await _client
          .from('customers')
          .select()
          .eq('phone', prettyPhone)
          .maybeSingle();
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } catch (_) {}
    return null;
  }

  /// Find an existing customer by their Supabase auth UID.
  Future<CustomerModel?> findCustomerByAuthId(String authId) async {
    final local = _db.customers.firstWhereOrNull((c) => c.id == authId);
    if (local != null) return local;
    try {
      final res = await _client
          .from('customers')
          .select()
          .eq('id', authId)
          .maybeSingle();
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        _db.customers.add(cust);
        return cust;
      }
    } catch (_) {}
    return null;
  }

  /// Register a new customer (upserts to both local + Supabase).
  /// Uses the Supabase auth user ID as the customer ID.
  Future<CustomerModel> register(
      String authId, String phone, String name, {String? token}) async {
    final effectiveToken = token ?? _client.auth.currentSession?.accessToken;
    final row = CustomerModel(
      id: authId,
      name: name,
      phone: phone,
      accessToken: effectiveToken,
      tokenUpdatedAt: effectiveToken != null ? DateTime.now() : null,
    );
    _db.customers.add(row);
    await _db.saveCustomer(row);
    return row;
  }

  /// Sign out of Supabase Auth.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      dev.log('[AuthRepo] signOut error: $e');
    }
  }

  /// Get the current auth user (if any).
  User? get currentAuthUser => _client.auth.currentUser;

  /// Get the current auth session access token (if any).
  String? get currentSessionToken => _client.auth.currentSession?.accessToken;
}
