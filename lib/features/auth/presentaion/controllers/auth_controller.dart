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

  final phoneController = TextEditingController(text: '100 123 4567');
  final nameController = TextEditingController();
  final otpController = TextEditingController(text: AuthRepo.demoOtp);

  final phoneError = RxnString();
  final otpError = RxnString();
  final nameError = RxnString();
  final sending = false.obs;
  final verifying = false.obs;
  final saving = false.obs;
  final resendIn = 0.obs;
  final lockedFor = 0.obs;

  String phone = '';
  int _attempts = 0;
  Timer? _timer;

  SessionService get _session => Get.find<SessionService>();

  Future<void> sendCode() async {
    final pretty = FormatHelper.parseEgPhone(phoneController.text);
    if (pretty == null) {
      phoneError.value = 'login.bad'.tr;
      return;
    }
    phoneError.value = null;
    sending.value = true;
    await _repo.sendOtp(pretty);
    sending.value = false;
    phone = pretty;
    otpError.value = null;
    otpController.text = AuthRepo.demoOtp;
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
    await _repo.sendOtp(phone);
    sending.value = false;
    _startTimer(resend: 30);
    Utils.getSnakBar(message: 'otp.sent'.trParams({'phone': phone}), type: TosterTypes.sucsses);
  }

  void changeNumber() => Get.back();

  Future<void> verify() async {
    if (lockedFor.value > 0) {
      otpError.value = 'otp.locked'.tr;
      return;
    }
    final code = otpController.text.trim();
    verifying.value = true;
    otpError.value = null;
    final error = await _repo.verifyOtp(phone, code);
    verifying.value = false;
    if (error != null) {
      if (error == 'otp.invalid') {
        _attempts++;
        if (_attempts >= 5) {
          _attempts = 0;
          _startTimer(lock: 60);
          otpError.value = 'otp.locked'.tr;
          return;
        }
      }
      otpError.value = error.tr;
      return;
    }
    final existing = _repo.findCustomer(phone);
    if (existing == null) {
      nameController.clear();
      nameError.value = null;
      Get.toNamed(Routes.profileSetupRoute);
      return;
    }
    await _session.signIn(existing);
    Utils.getSnakBar(message: 'otp.success'.tr, type: TosterTypes.sucsses);
    AuthGuard.completeLogin();
  }

  Future<void> saveName() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      nameError.value = 'profile.nameErr'.tr;
      return;
    }
    saving.value = true;
    final row = await _repo.register(phone, name);
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
