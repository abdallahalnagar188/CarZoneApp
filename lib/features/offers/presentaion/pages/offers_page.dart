import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/offers_controller.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OffersController>();
    return Scaffold(
      appBar: AppTopBar(title: 'offers.title'.tr),
      body: Obx(() {
        if (controller.loading.value) return const AppShimmerList(itemHeight: 168);
        if (controller.offers.isEmpty && controller.error != null) {
          return AppErrorState(message: controller.error, onRetry: controller.load);
        }
        if (controller.offers.isEmpty) {
          return CustomEmptyState(icon: Iconsax.ticket_discount, title: 'offers.title'.tr);
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: EdgeInsets.all(20.r),
            itemCount: controller.offers.length,
            separatorBuilder: (_, __) => SizedBox(height: 14.h),
            itemBuilder: (_, i) {
              final offer = controller.offers[i];
              return OfferCard(
                offer: offer,
                washName: controller.washName(offer),
                onTap: () => controller.open(offer),
              );
            },
          ),
        );
      }),
    );
  }
}
