
import 'package:get/get.dart';

import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../routing/navigator_keys.dart';
import '../services/session_service.dart';

class AuthGuard {
  AuthGuard._();

  static const _authRoutes = [
    Routes.loginRoute,
    Routes.otpRoute,
    Routes.profileSetupRoute,
  ];

  static void run(void Function() action) {
    final session = Get.isRegistered<SessionService>() ? Get.find<SessionService>() : null;
    if (session?.isLoggedIn ?? false) {
      action();
      return;
    }
    if (session != null) {
      session.pendingAction = action;
    }
    AppNav.to(Routes.loginRoute);
  }

  static void completeLogin() {
    final session = Get.isRegistered<SessionService>() ? Get.find<SessionService>() : null;
    final action = session?.pendingAction;
    session?.clearReturn();
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.popUntil((route) => !_authRoutes.contains(route.settings.name));
    } else {
      Get.until((route) => !_authRoutes.contains(route.settings.name));
    }
    action?.call();
  }
}
