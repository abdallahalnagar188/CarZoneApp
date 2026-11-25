import 'package:get/get.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/local/cache_controller.dart';
import '../../../../core/local/lang_controller.dart';
import '../../../../core/local/theme_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';

class SettingsController extends GetxController {
  final reminders = true.obs;
  final offers = true.obs;
  final legalTab = 0.obs;

  LanguageGetxController get _lang => Get.find<LanguageGetxController>();
  ThemeController get theme => Get.find<ThemeController>();

  bool get isArabic => _lang.isArabic;

  @override
  void onInit() {
    super.onInit();
    final cache = CacheController();
    final r = cache.getter(key: CacheKeys.notifReminders);
    final o = cache.getter(key: CacheKeys.notifOffers);
    if (r is bool) reminders.value = r;
    if (o is bool) offers.value = o;
    // The server copy wins when the account has one (GAP-036).
    final me = Get.isRegistered<SessionService>() ? Get.find<SessionService>().user.value : null;
    if (me?.notifyReminders != null) reminders.value = me!.notifyReminders!;
    if (me?.notifyOffers != null) offers.value = me!.notifyOffers!;
    legalTab.value = Get.arguments == 'privacy' ? 1 : 0;
  }

  Future<void> setLanguage(String code) async {
    await _lang.changeLanguage(code);
    update();
  }

  Future<void> setDark(bool value) => theme.setDarkMode(value);

  Future<void> setReminders(bool v) async {
    reminders.value = v;
    await CacheController().setter(key: CacheKeys.notifReminders, value: v);
    // send-push reads it from the customer row (GAP-036).
    await _saveOnServer({'notify_reminders': v});
  }

  Future<void> setOffers(bool v) async {
    offers.value = v;
    await CacheController().setter(key: CacheKeys.notifOffers, value: v);
    await _saveOnServer({'notify_offers': v});
  }

  Future<void> _saveOnServer(Map<String, dynamic> changes) async {
    if (!Get.isRegistered<SessionService>()) return;
    await Get.find<SessionService>().saveCustomerSettings(changes);
  }

  void openLegal(String doc) => Get.toNamed(Routes.legalRoute, arguments: doc);

  void setLegalTab(int i) => legalTab.value = i;
}
