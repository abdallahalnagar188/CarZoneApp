import 'package:get/get.dart';

import '../../features/auth/presentaion/pages/login_page.dart';
import '../../features/auth/presentaion/pages/otp_page.dart';
import '../../features/auth/presentaion/pages/profile_setup_page.dart';
import '../../features/booking/presentaion/pages/booking_car_page.dart';
import '../../features/booking/presentaion/pages/booking_service_page.dart';
import '../../features/booking/presentaion/pages/booking_slot_page.dart';
import '../../features/booking/presentaion/pages/booking_success_page.dart';
import '../../features/booking/presentaion/pages/booking_summary_page.dart';
import '../../features/bookings/presentaion/pages/booking_details_page.dart';
import '../../features/bookings/presentaion/pages/report_page.dart';
import '../../features/bookings/presentaion/pages/review_page.dart';
import '../../features/cars/presentaion/pages/car_form_page.dart';
import '../../features/cars/presentaion/pages/cars_page.dart';
import '../../features/discovery/presentaion/pages/results_page.dart';
import '../../features/discovery/presentaion/pages/search_page.dart';
import '../../features/favorites/presentaion/pages/favorites_page.dart';
import '../../features/main/presentaion/pages/main_page.dart';
import '../../features/notifications/presentaion/pages/notifications_page.dart';
import '../../features/offers/presentaion/pages/offers_page.dart';
import '../../features/onboarding/presentaion/pages/onboarding_page.dart';
import '../../features/profile/presentaion/pages/edit_profile_page.dart';
import '../../features/settings/presentaion/pages/help_page.dart';
import '../../features/settings/presentaion/pages/legal_page.dart';
import '../../features/settings/presentaion/pages/settings_page.dart';
import '../../features/splash/presentaion/pages/splash_page.dart';
import '../../features/wash_details/presentaion/pages/gallery_viewer_page.dart';
import '../../features/wash_details/presentaion/pages/reviews_page.dart';
import '../../features/wash_details/presentaion/pages/wash_details_page.dart';

class Routes {
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String profileSetupRoute = '/profile_setup';
  static const String mainRoute = '/main';
  static const String searchRoute = '/search';
  static const String resultsRoute = '/results';
  static const String offersRoute = '/offers';
  static const String washDetailsRoute = '/wash';
  static const String reviewsRoute = '/wash_reviews';
  static const String galleryRoute = '/wash_gallery';
  static const String bookServiceRoute = '/book_service';
  static const String bookCarRoute = '/book_car';
  static const String bookSlotRoute = '/book_slot';
  static const String bookSummaryRoute = '/book_summary';
  static const String bookSuccessRoute = '/book_success';
  static const String bookingDetailsRoute = '/booking';
  static const String reviewRoute = '/booking_review';
  static const String reportRoute = '/booking_report';
  static const String carsRoute = '/cars';
  static const String carFormRoute = '/car_form';
  static const String favoritesRoute = '/favorites';
  static const String notificationsRoute = '/notifications';
  static const String editProfileRoute = '/edit_profile';
  static const String settingsRoute = '/settings';
  static const String legalRoute = '/legal';
  static const String helpRoute = '/help';
}

const _duration = Duration(milliseconds: 300);

List<GetPage<dynamic>> appPages = [
  GetPage(name: Routes.splashRoute, page: () => const SplashPage(), transitionDuration: _duration),
  GetPage(name: Routes.onboardingRoute, page: () => const OnboardingPage(), transition: Transition.fadeIn, transitionDuration: _duration),
  GetPage(name: Routes.loginRoute, page: () => const LoginPage(), transitionDuration: _duration),
  GetPage(name: Routes.otpRoute, page: () => const OtpPage(), transitionDuration: _duration),
  GetPage(name: Routes.profileSetupRoute, page: () => const ProfileSetupPage(), transitionDuration: _duration),
  GetPage(name: Routes.mainRoute, page: () => const MainPage(), transition: Transition.fadeIn, transitionDuration: _duration),
  GetPage(name: Routes.searchRoute, page: () => const SearchPage(), transitionDuration: _duration),
  GetPage(name: Routes.resultsRoute, page: () => const ResultsPage(), transitionDuration: _duration),
  GetPage(name: Routes.offersRoute, page: () => const OffersPage(), transitionDuration: _duration),
  GetPage(name: Routes.washDetailsRoute, page: () => const WashDetailsPage(), transitionDuration: _duration),
  GetPage(name: Routes.reviewsRoute, page: () => const ReviewsPage(), transitionDuration: _duration),
  GetPage(name: Routes.galleryRoute, page: () => const GalleryViewerPage(), transition: Transition.fadeIn, transitionDuration: _duration),
  GetPage(name: Routes.bookServiceRoute, page: () => const BookingServicePage(), transitionDuration: _duration),
  GetPage(name: Routes.bookCarRoute, page: () => const BookingCarPage(), transitionDuration: _duration),
  GetPage(name: Routes.bookSlotRoute, page: () => const BookingSlotPage(), transitionDuration: _duration),
  GetPage(name: Routes.bookSummaryRoute, page: () => const BookingSummaryPage(), transitionDuration: _duration),
  GetPage(name: Routes.bookSuccessRoute, page: () => const BookingSuccessPage(), transition: Transition.zoom, transitionDuration: _duration),
  GetPage(name: Routes.bookingDetailsRoute, page: () => const BookingDetailsPage(), transitionDuration: _duration),
  GetPage(name: Routes.reviewRoute, page: () => const ReviewPage(), transitionDuration: _duration),
  GetPage(name: Routes.reportRoute, page: () => const ReportPage(), transitionDuration: _duration),
  GetPage(name: Routes.carsRoute, page: () => const CarsPage(), transitionDuration: _duration),
  GetPage(name: Routes.carFormRoute, page: () => const CarFormPage(), transitionDuration: _duration),
  GetPage(name: Routes.favoritesRoute, page: () => const FavoritesPage(), transitionDuration: _duration),
  GetPage(name: Routes.notificationsRoute, page: () => const NotificationsPage(), transitionDuration: _duration),
  GetPage(name: Routes.editProfileRoute, page: () => const EditProfilePage(), transitionDuration: _duration),
  GetPage(name: Routes.settingsRoute, page: () => const SettingsPage(), transitionDuration: _duration),
  GetPage(name: Routes.legalRoute, page: () => const LegalPage(), transitionDuration: _duration),
  GetPage(name: Routes.helpRoute, page: () => const HelpPage(), transitionDuration: _duration),
];
