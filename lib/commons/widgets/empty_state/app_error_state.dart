import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/services/connectivity_service.dart';
import 'custom_empty_state.dart';

/// Failed load with a retry button. Pass the text from
/// `ApiException.messageFor(error)`; offline gets its own icon and title.
class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const AppErrorState({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final offline = !ConnectivityService.online;
    return CustomEmptyState(
      icon: offline ? Iconsax.wifi_square : Iconsax.cloud_cross,
      title: (offline ? 'error.offlineTitle' : 'error.title').tr,
      body: message ?? 'error.body'.tr,
      actionText: 'error.retry'.tr,
      onAction: onRetry,
      color: offline ? AppColors.warning : AppColors.danger,
    );
  }
}
