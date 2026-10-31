import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../commons/widgets/dialogs/app_confirm_dialog.dart';
import '../../commons/widgets/snack_bar/snack_bar.dart';
import '../enums/enums.dart';
import '../routing/navigator_keys.dart';

class Utils {
  static OverlayEntry? _snackEntry;
  static Timer? _snackTimer;

  static void getSnakBar({
    String? message,
    required TosterTypes? type,
  }) {
    final overlayContext = rootNavigatorKey.currentContext ?? Get.overlayContext;
    if (overlayContext == null) return;
    final overlay = Overlay.maybeOf(overlayContext, rootOverlay: true);
    if (overlay == null) return;

    dismissSnackBar();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 12.h,
        left: 16.w,
        right: 16.w,
        child: Material(
          color: Colors.transparent,
          child: AppSnackBarContent(
            message: message ?? '',
            type: type ?? TosterTypes.failed,
            onClose: dismissSnackBar,
          ),
        ),
      ),
    );
    _snackEntry = entry;
    overlay.insert(entry);
    _snackTimer = Timer(const Duration(seconds: 3), dismissSnackBar);
  }

  static void dismissSnackBar() {
    _snackTimer?.cancel();
    _snackTimer = null;
    final entry = _snackEntry;
    _snackEntry = null;
    entry?.remove();
  }

  static Future<bool> confirm({
    required String title,
    String? body,
    required String okText,
    String? cancelText,
    bool danger = false,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AppConfirmDialog(
          title: title,
          body: body,
          okText: okText,
          cancelText: cancelText ?? 'common.cancel'.tr,
          danger: danger,
        ),
      );
      return result ?? false;
    }
    final result = await Get.dialog<bool>(
      AppConfirmDialog(
        title: title,
        body: body,
        okText: okText,
        cancelText: cancelText ?? 'common.cancel'.tr,
        danger: danger,
      ),
    );
    return result ?? false;
  }
}
