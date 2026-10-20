import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../commons/models/customer_model.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../data/repo/auth_repo.dart';

class AuthController extends GetxController {
  final _repo = AuthRepo();

  final phoneController = TextEditingController(text: '');
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  final phoneError = RxnString();
  final otpError = RxnString();
  final nameError = RxnString();
  final sending = false.obs;
  final verifying = false.obs;
  final saving = false.obs;
  final googleSigningIn = false.obs;
  final resendIn = 0.obs;
  final lockedFor = 0.obs;

  /// Pretty-formatted Egyptian phone e.g. "+20 100 123 4567"
  String phone = '';

  /// E.164 phone number e.g. "+201001234567" (for Supabase Auth)
  String _e164Phone = '';

  int _attempts = 0;
  Timer? _timer;

  SessionService get _session => Get.find<SessionService>();

  /// Initiate native in-app Google Sign-In popup without opening Chrome app
  Future<void> signInWithGoogle() async {
    if (googleSigningIn.value || sending.value) return;
    googleSigningIn.value = true;
    try {
      if (_repo.canUseNativeGoogle) {
        final res = await _repo.signInWithGoogleNative();
        if (res == null) {
          // User dismissed or canceled the popup dialog
          return;
        }
        await _handleSuccessfulAuth(res);
      } else {
        // Fallback: in-app browser view
        final started = await _repo.signInWithGoogleInAppBrowser();
        if (!started) {
          Utils.getSnakBar(message: 'login.google_failed'.tr, type: TosterTypes.failed);
        }
      }
    } on AuthException catch (e) {
      // Not an OTP failure: show the Google message, keep the raw cause in the log.
      debugPrint('[AuthController] signInWithGoogle AuthException: ${e.message} (status: ${e.statusCode}, code: ${e.code})');
      Utils.getSnakBar(message: 'login.google_failed'.tr, type: TosterTypes.failed);
    } catch (e) {
      debugPrint('[AuthController] signInWithGoogle unexpected error: $e');
      Utils.getSnakBar(message: 'login.google_failed'.tr, type: TosterTypes.failed);
    } finally {
      googleSigningIn.value = false;
    }
  }

  Future<void> _handleSuccessfulAuth(AuthResponse res) async {
    final authUser = res.user ?? _repo.currentAuthUser;
    if (authUser == null) {
      Utils.getSnakBar(message: 'login.google_failed'.tr, type: TosterTypes.failed);
      return;
    }

    final token = res.session?.accessToken ?? _repo.currentSessionToken;
    if (token != null) {
      await _session.saveToken(token);
    }

    var existing = await _repo.findCustomerByAuthId(authUser.id);
    if (existing == null && authUser.phone != null && authUser.phone!.isNotEmpty) {
      existing = await _repo.findCustomerByPhone(authUser.phone!);
    }

    if (existing != null) {
      await _session.signIn(existing, token: token);
      Utils.getSnakBar(message: 'otp.success'.tr, type: TosterTypes.sucsses);
      AuthGuard.completeLogin();
    } else {
      nameController.clear();
      final gName = authUser.userMetadata?['full_name'] ??
          authUser.userMetadata?['name'] ??
          '';
      if (gName.toString().isNotEmpty) {
        nameController.text = gName.toString();
      }
      if (authUser.phone != null && authUser.phone!.isNotEmpty) {
        phone = authUser.phone!;
        phoneController.text = authUser.phone!;
      }
      Get.toNamed(Routes.profileSetupRoute);
    }
  }

  /// Parse the input to a pretty phone and E.164 format, then send OTP.
  Future<void> sendCode() async {
    final rawInput = phoneController.text.trim();
    if (rawInput.isEmpty) {
      phoneError.value = null;
      Utils.getSnakBar(message: 'login.bad'.tr, type: TosterTypes.failed);
      return;
    }

    final pretty = FormatHelper.parseEgPhone(rawInput);
    if (pretty == null) {
      phoneError.value = null;
      Utils.getSnakBar(message: 'login.bad'.tr, type: TosterTypes.failed);
      return;
    }

    phoneError.value = null;
    phone = pretty;
    // Convert pretty "+20 100 123 4567" to E.164 "+201001234567"
    _e164Phone = pretty.replaceAll(' ', '');

    sending.value = true;
    final error = await _repo.sendOtp(_e164Phone);
    sending.value = false;

    if (error != null) {
      phoneError.value = null; // Do not expose backend error inline
      Utils.getSnakBar(message: error, type: TosterTypes.failed);
      return;
    }

    otpError.value = null;
    otpController.clear();
    _startTimer(resend: 30);
    Get.toNamed(Routes.otpRoute);
    Utils.getSnakBar(
      message: 'otp.sent'.trParams({'phone': phone}),
      type: TosterTypes.sucsses,
    );
  }

  void _startTimer({int resend = 0, int lock = 0}) {
    if (resend > 0) resendIn.value = resend;
    if (lock > 0) lockedFor.value = lock;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendIn.value > 0) resendIn.value--;
      if (lockedFor.value > 0) lockedFor.value--;
      if (resendIn.value == 0 && lockedFor.value == 0) t.cancel();
    });
  }

  Future<void> resend() async {
    if (resendIn.value > 0 || lockedFor.value > 0) return;
    sending.value = true;
    final error = await _repo.sendOtp(_e164Phone);
    sending.value = false;

    if (error != null) {
      Utils.getSnakBar(message: error, type: TosterTypes.failed);
      return;
    }
    _startTimer(resend: 30);
    Utils.getSnakBar(
      message: 'otp.sent'.trParams({'phone': phone}),
      type: TosterTypes.sucsses,
    );
  }

  void changeNumber() => Get.back();

  Future<void> verify() async {
    if (lockedFor.value > 0) {
      otpError.value = null;
      Utils.getSnakBar(message: 'otp.locked'.tr, type: TosterTypes.warning);
      return;
    }
    final code = otpController.text.trim();
    if (code.length != 6) {
      otpError.value = null;
      Utils.getSnakBar(message: 'otp.invalid'.tr, type: TosterTypes.warning);
      return;
    }

    verifying.value = true;
    otpError.value = null;
    final error = await _repo.verifyOtp(_e164Phone, code);
    verifying.value = false;

    if (error != null) {
      _attempts++;
      if (_attempts >= 5) {
        _attempts = 0;
        _startTimer(lock: 60);
        otpError.value = null;
        Utils.getSnakBar(message: 'otp.locked'.tr, type: TosterTypes.warning);
        return;
      }
      otpError.value = null;
      Utils.getSnakBar(message: error, type: TosterTypes.failed);
      return;
    }

    // OTP verified — Supabase session is now active.
    // Check if we have an existing customer record (or link seeded customer).
    final authUser = _repo.currentAuthUser;
    if (authUser == null) {
      otpError.value = null;
      Utils.getSnakBar(message: 'otp.error'.tr, type: TosterTypes.failed);
      return;
    }

    final token = _repo.currentSessionToken;
    // Try atomic profile sync first (links an unlinked customer with the verified phone)
    CustomerModel? existing;
    try {
      existing = await _repo.syncProfile(phone: _e164Phone, token: token);
    } on PhoneInUseException {
      Utils.getSnakBar(message: 'auth.phoneInUse'.tr, type: TosterTypes.failed);
      return;
    }
    existing ??= await _repo.findCustomerByAuthId(authUser.id);
    existing ??= await _repo.findCustomerByPhone(_e164Phone);

    if (existing == null) {
      // New user — go to profile setup to collect their name
      nameController.clear();
      nameError.value = null;
      Get.toNamed(Routes.profileSetupRoute);
      return;
    }

    // Existing user — sign in with active session token
    if (token != null) {
      await _session.saveToken(token);
    }
    await _session.signIn(existing, token: token);
    Utils.getSnakBar(
        message: 'otp.success'.tr, type: TosterTypes.sucsses);
    AuthGuard.completeLogin();
  }

  Future<void> saveName() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      nameError.value = null;
      Utils.getSnakBar(message: 'profile.nameErr'.tr, type: TosterTypes.warning);
      return;
    }

    final authUser = _repo.currentAuthUser;
    if (authUser == null) {
      nameError.value = null;
      Utils.getSnakBar(message: 'otp.error'.tr, type: TosterTypes.failed);
      return;
    }

    var effectivePhone = _e164Phone.isNotEmpty
        ? _e164Phone
        : (authUser.phone ?? phone.replaceAll(' ', ''));

    if (effectivePhone.isEmpty) {
      final input = phoneController.text.trim();
      final parsed = FormatHelper.parseEgPhone(input);
      if (parsed == null) {
        phoneError.value = null;
        Utils.getSnakBar(message: 'login.bad'.tr, type: TosterTypes.warning);
        return;
      }
      effectivePhone = parsed.replaceAll(' ', '');
    }

    final token = _repo.currentSessionToken;
    saving.value = true;
    final CustomerModel row;
    try {
      row = await _repo.register(authUser.id, effectivePhone, name, token: token);
    } on PhoneInUseException {
      Utils.getSnakBar(message: 'auth.phoneInUse'.tr, type: TosterTypes.failed);
      return;
    } catch (_) {
      Utils.getSnakBar(message: 'profile.saveFailed'.tr, type: TosterTypes.failed);
      return;
    } finally {
      saving.value = false;
    }
    await _session.signIn(row, token: token);
    Utils.getSnakBar(message: 'otp.success'.tr, type: TosterTypes.sucsses);
    AuthGuard.completeLogin();
  }

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    nameController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
