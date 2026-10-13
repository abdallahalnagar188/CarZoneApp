import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/services/pricing_service.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_footer.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/service_option_tile.dart';

class BookingServicePage extends StatelessWidget {
  const BookingServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    final pricing = PricingService();
    final theme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.leaveFlow();
      },
      child: Scaffold(
        appBar: AppTopBar(title: controller.branch?.name.value ?? '', onBack: controller.leaveFlow),
        bottomNavigationBar: Obx(
          () => BookingFooter(
            title: 'book.continue'.tr,
            enabled: controller.primaryId.value != null,
            onTap: controller.continueFromService,
          ),
        ),
        body: Obx(
          () => ListView(
            padding: EdgeInsets.only(bottom: 20.h),
            children: [
              const BookingStepHeader(step: 1, labelKey: 'book.service'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    14.height,
                    Text('book.primary'.tr, style: theme.titleLarge),
                    12.height,
                    ...controller.primaries.map((s) => ServiceOptionTile(
                          service: s,
                          selected: controller.primaryId.value == s.id,
                          offer: pricing.offerFor(controller.branchId.value, s.id),
                          onTap: () => controller.selectPrimary(s.id),
                        )),
                    14.height,
                    Text('book.addons'.tr, style: theme.titleLarge),
                    ...controller.addons.map((s) => AddonTile(
                          service: s,
                          selected: controller.addonIds.contains(s.id),
                          onTap: () => controller.toggleAddon(s.id),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
