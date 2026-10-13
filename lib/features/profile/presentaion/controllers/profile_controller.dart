import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/auth_guard.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/carzone_db_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../booking/presentaion/controllers/booking_controller.dart';
import '../../../main/presentaion/controllers/main_controller.dart';

class ProfileController extends GetxController {
  final nameController = TextEditingController();
  final nameError = RxnString();
  final saving = false.obs;

  SessionService get session => Get.find<SessionService>();
  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  int get unread => _db.notifications.where((n) => n.userId == session.userId && !n.read).length;

  void login() => AuthGuard.run(() {});

  void openCars() => Get.toNamed(Routes.carsRoute);

  void openBookings() => Get.find<MainController>().changeTab(2);

  void openFavorites() => Get.toNamed(Routes.favoritesRoute);

  void openNotifications() => Get.toNamed(Routes.notificationsRoute);

  void openSettings() => Get.toNamed(Routes.settingsRoute);

  void openLegal() => Get.toNamed(Routes.legalRoute, arguments: 'terms');

  void openHelp() => Get.toNamed(Routes.helpRoute);

  void openEdit() {
    nameController.text = session.user.value?.name ?? '';
    nameError.value = null;
    Get.toNamed(Routes.editProfileRoute);
  }

  Future<void> saveName() async {
    final name = nameController.text.trim();
    if (name.length < 2) {
      nameError.value = 'profile.nameErr'.tr;
      return;
    }
    saving.value = true;
    await Future.delayed(const Duration(milliseconds: 300));
    session.user.value?.name = name;
    session.user.refresh();
    saving.value = false;
    Get.back();
  }

  Future<void> logout() async {
    final ok = await Utils.confirm(title: 'profile.logoutAsk'.tr, okText: 'profile.logout'.tr, danger: true);
    if (!ok) return;
    await session.signOut();
    Get.find<BookingController>().clearDraft();
    Get.find<MainController>().changeTab(0);
    Utils.getSnakBar(message: 'profile.logout'.tr, type: TosterTypes.sucsses);
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }
}
