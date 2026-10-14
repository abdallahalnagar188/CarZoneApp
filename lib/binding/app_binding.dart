import 'package:get/get.dart';

import '../core/local/lang_controller.dart';
import '../core/local/theme_controller.dart';
import '../core/services/carzone_db_service.dart';
import '../core/services/deep_link_service.dart';
import '../core/services/session_service.dart';
import '../features/auth/presentaion/controllers/auth_controller.dart';
import '../features/booking/presentaion/controllers/booking_controller.dart';
import '../features/bookings/presentaion/controllers/booking_details_controller.dart';
import '../features/bookings/presentaion/controllers/bookings_controller.dart';
import '../features/bookings/presentaion/controllers/report_controller.dart';
import '../features/bookings/presentaion/controllers/review_controller.dart';
import '../features/cars/presentaion/controllers/cars_controller.dart';
import '../features/discovery/presentaion/controllers/results_controller.dart';
import '../features/discovery/presentaion/controllers/wash_search_controller.dart';
import '../features/favorites/presentaion/controllers/favorites_controller.dart';
import '../features/home/presentaion/controllers/home_controller.dart';
import '../features/main/presentaion/controllers/main_controller.dart';
import '../features/map/presentaion/controllers/wash_map_controller.dart';
import '../features/notifications/presentaion/controllers/notifications_controller.dart';
import '../features/offers/presentaion/controllers/offers_controller.dart';
import '../features/onboarding/presentaion/controllers/onboarding_controller.dart';
import '../features/profile/presentaion/controllers/profile_controller.dart';
import '../features/settings/presentaion/controllers/settings_controller.dart';
import '../features/splash/presentaion/controllers/splash_controller.dart';
import '../features/wash_details/presentaion/controllers/wash_details_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LanguageGetxController(), fenix: true);
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
    if (!Get.isRegistered<CarzoneDbService>()) {
      Get.put(CarzoneDbService().init(), permanent: true);
    }
    if (!Get.isRegistered<SessionService>()) {
      Get.put(SessionService().init(), permanent: true);
    }
    if (!Get.isRegistered<DeepLinkService>()) {
      Get.put(DeepLinkService(), permanent: true);
      Get.find<DeepLinkService>().init();
    }
    if (!Get.isRegistered<BookingController>()) {
      Get.put(BookingController(), permanent: true);
    }
    Get.lazyPut(() => SplashController(), fenix: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => MainController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => FavoritesController(), fenix: true);
    Get.lazyPut(() => WashSearchController(), fenix: true);
    Get.lazyPut(() => ResultsController(), fenix: true);
    Get.lazyPut(() => WashMapController(), fenix: true);
    Get.lazyPut(() => OffersController(), fenix: true);
    Get.lazyPut(() => WashDetailsController(), fenix: true);
    Get.lazyPut(() => BookingsController(), fenix: true);
    Get.lazyPut(() => BookingDetailsController(), fenix: true);
    Get.lazyPut(() => ReviewController(), fenix: true);
    Get.lazyPut(() => ReportController(), fenix: true);
    Get.lazyPut(() => CarsController(), fenix: true);
    Get.lazyPut(() => NotificationsController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
  }
}
