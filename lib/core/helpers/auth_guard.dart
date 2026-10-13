import 'package:get/get.dart';

import '../routing/app_routes.dart';
import '../services/session_service.dart';

class AuthGuard {
  AuthGuard._();

  static const _authRoutes = [
    Routes.loginRoute,
    Routes.otpRoute,
    Routes.profileSetupRoute,
  ];

  static void run(void Function() action) {
    final session = Get.find<SessionService>();
    if (session.isLoggedIn) {
      action();
      return;
    }
    session.pendingAction = action;
    Get.toNamed(Routes.loginRoute);
  }

  static void completeLogin() {
    final session = Get.find<SessionService>();
    final action = session.pendingAction;
    session.clearReturn();
    Get.until((route) => !_authRoutes.contains(route.settings.name));
    action?.call();
  }
}
