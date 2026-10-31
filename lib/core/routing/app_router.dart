import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'app_routes.dart';
import 'navigator_keys.dart';

class AppNav {
  AppNav._();

  static dynamic currentArguments;
  static String currentRoute = Routes.splashRoute;

  static void to(String route, {dynamic arguments}) {
    currentArguments = arguments;
    currentRoute = route;
    rootNavigatorKey.currentContext?.push(route, extra: arguments);
  }

  static void offAll(String route, {dynamic arguments}) {
    currentArguments = arguments;
    currentRoute = route;
    rootNavigatorKey.currentContext?.go(route, extra: arguments);
  }

  static void back<T>([T? result]) {
    if (rootNavigatorKey.currentContext?.canPop() ?? false) {
      rootNavigatorKey.currentContext?.pop(result);
    }
  }
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splashRoute,
  routes: [
    GoRoute(
      path: Routes.splashRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.splashRoute;
        AppNav.currentArguments = state.extra;
        return const SplashPage();
      },
    ),
    GoRoute(
      path: Routes.onboardingRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.onboardingRoute;
        AppNav.currentArguments = state.extra;
        return const OnboardingPage();
      },
    ),
    GoRoute(
      path: Routes.loginRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.loginRoute;
        AppNav.currentArguments = state.extra;
        return const LoginPage();
      },
    ),
    GoRoute(
      path: Routes.otpRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.otpRoute;
        AppNav.currentArguments = state.extra;
        return const OtpPage();
      },
    ),
    GoRoute(
      path: Routes.profileSetupRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.profileSetupRoute;
        AppNav.currentArguments = state.extra;
        return const ProfileSetupPage();
      },
    ),
    GoRoute(
      path: Routes.mainRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.mainRoute;
        AppNav.currentArguments = state.extra;
        return const MainPage();
      },
    ),
    GoRoute(
      path: Routes.searchRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.searchRoute;
        AppNav.currentArguments = state.extra;
        return const SearchPage();
      },
    ),
    GoRoute(
      path: Routes.resultsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.resultsRoute;
        AppNav.currentArguments = state.extra;
        return const ResultsPage();
      },
    ),
    GoRoute(
      path: Routes.offersRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.offersRoute;
        AppNav.currentArguments = state.extra;
        return const OffersPage();
      },
    ),
    GoRoute(
      path: Routes.washDetailsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.washDetailsRoute;
        AppNav.currentArguments = state.extra;
        return const WashDetailsPage();
      },
    ),
    GoRoute(
      path: Routes.reviewsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.reviewsRoute;
        AppNav.currentArguments = state.extra;
        return const ReviewsPage();
      },
    ),
    GoRoute(
      path: Routes.galleryRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.galleryRoute;
        AppNav.currentArguments = state.extra;
        return const GalleryViewerPage();
      },
    ),
    GoRoute(
      path: Routes.bookServiceRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.bookServiceRoute;
        AppNav.currentArguments = state.extra;
        return const BookingServicePage();
      },
    ),
    GoRoute(
      path: Routes.bookCarRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.bookCarRoute;
        AppNav.currentArguments = state.extra;
        return const BookingCarPage();
      },
    ),
    GoRoute(
      path: Routes.bookSlotRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.bookSlotRoute;
        AppNav.currentArguments = state.extra;
        return const BookingSlotPage();
      },
    ),
    GoRoute(
      path: Routes.bookSummaryRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.bookSummaryRoute;
        AppNav.currentArguments = state.extra;
        return const BookingSummaryPage();
      },
    ),
    GoRoute(
      path: Routes.bookSuccessRoute,
      pageBuilder: (context, state) {
        AppNav.currentRoute = Routes.bookSuccessRoute;
        AppNav.currentArguments = state.extra;
        return CustomTransitionPage(
          key: state.pageKey,
          child: const BookingSuccessPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(scale: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: Routes.bookingDetailsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.bookingDetailsRoute;
        AppNav.currentArguments = state.extra;
        return const BookingDetailsPage();
      },
    ),
    GoRoute(
      path: Routes.reviewRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.reviewRoute;
        AppNav.currentArguments = state.extra;
        return const ReviewPage();
      },
    ),
    GoRoute(
      path: Routes.reportRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.reportRoute;
        AppNav.currentArguments = state.extra;
        return const ReportPage();
      },
    ),
    GoRoute(
      path: Routes.carsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.carsRoute;
        AppNav.currentArguments = state.extra;
        return const CarsPage();
      },
    ),
    GoRoute(
      path: Routes.carFormRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.carFormRoute;
        AppNav.currentArguments = state.extra;
        return const CarFormPage();
      },
    ),
    GoRoute(
      path: Routes.favoritesRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.favoritesRoute;
        AppNav.currentArguments = state.extra;
        return const FavoritesPage();
      },
    ),
    GoRoute(
      path: Routes.notificationsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.notificationsRoute;
        AppNav.currentArguments = state.extra;
        return const NotificationsPage();
      },
    ),
    GoRoute(
      path: Routes.editProfileRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.editProfileRoute;
        AppNav.currentArguments = state.extra;
        return const EditProfilePage();
      },
    ),
    GoRoute(
      path: Routes.settingsRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.settingsRoute;
        AppNav.currentArguments = state.extra;
        return const SettingsPage();
      },
    ),
    GoRoute(
      path: Routes.legalRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.legalRoute;
        AppNav.currentArguments = state.extra;
        return const LegalPage();
      },
    ),
    GoRoute(
      path: Routes.helpRoute,
      builder: (context, state) {
        AppNav.currentRoute = Routes.helpRoute;
        AppNav.currentArguments = state.extra;
        return const HelpPage();
      },
    ),
  ],
);

