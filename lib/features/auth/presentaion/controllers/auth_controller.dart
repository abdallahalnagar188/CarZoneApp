import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  final resendIn = 0.obs;
  final lockedFor = 0.obs;

  /// Pretty-formatted Egyptian phone e.g. "+20 100 123 4567"
  String phone = '';

  /// E.164 phone number e.g. "+201001234567" (for Supabase Auth)
  String _e164Phone = '';

  int _attempts = 0;
  Timer? _timer;

  SessionService get _session => Get.find<SessionService>();

  /// Parse the input to a pretty phone and E.164 format, then send OTP.
  Future<void> sendCode() async {
    final pretty = FormatHelper.parseEgPhone(phoneController.text);
    if (pretty == null) {
      phoneError.value = 'login.bad'.tr;
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
      phoneError.value = error;
      return;
    }

    otpError.value = null;
    otpController.clear();
    _startTimer(resend: 30);
    Get.toNamed(Routes.otpRoute);
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
        type: TosterTypes.sucsses);
  }

  void changeNumber() => Get.back();

  Future<void> verify() async {
    if (lockedFor.value > 0) {
      otpError.value = 'otp.locked'.tr;
      return;
    }
    final code = otpController.text.trim();
    if (code.length != 6) {
      otpError.value = 'otp.invalid'.tr;
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
        otpError.value = 'otp.locked'.tr;
        return;
      }
      otpError.value = error;
      return;
    }

    // OTP verified — Supabase session is now active.
    // Check if we have an existing customer record.
    final authUser = _repo.currentAuthUser;
    if (authUser == null) {
      otpError.value = 'otp.error'.tr;
      return;
    }

    // Try to find existing customer by auth ID or phone
    var existing = _repo.findCustomerByAuthId(authUser.id);
    existing ??= _repo.findCustomerByPhone(phone);

    if (existing == null) {
      // New user — go to profile setup to collect their name
      nameController.clear();
      nameError.value = null;
      Get.toNamed(Routes.profileSetupRoute);
      return;
    }

    // Existing user — sign in
    await _session.signIn(existing);
    Utils.getSnakBar(
        message: 'otp.success'.tr, type: TosterTypes.sucsses);
    AuthGuard.completeLogin();
  }

  Future<void> saveName() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      nameError.value = 'profile.nameErr'.tr;
      return;
    }

    final authUser = _repo.currentAuthUser;
    if (authUser == null) {
      nameError.value = 'otp.error'.tr;
      return;
    }

    saving.value = true;
    final row = await _repo.register(authUser.id, phone, name);
    saving.value = false;
    await _session.signIn(row);
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
