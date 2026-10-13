import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_footer.dart';
import '../widgets/booking_step_header.dart';

class BookingCarPage extends StatelessWidget {
  const BookingCarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    return Scaffold(
      appBar: AppTopBar(title: controller.branch?.name.value ?? ''),
      bottomNavigationBar: Obx(
        () => BookingFooter(
          title: 'book.continue'.tr,
          enabled: controller.vehicleId.value != null,
          onTap: controller.continueFromCar,
        ),
      ),
      body: Obx(() {
        final list = controller.vehicles;
        return ListView(
          children: [
            const BookingStepHeader(step: 2, labelKey: 'book.car'),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  if (list.isEmpty)
                    CustomEmptyState(icon: Iconsax.car, title: 'empty.cars'.tr)
                  else
                    ...list.map((v) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: CarTile(
                            vehicle: v,
                            selected: controller.vehicleId.value == v.id,
                            onTap: () => controller.selectVehicle(v.id),
                          ),
                        )),
                  8.height,
                  AppButton(
                    title: 'book.addCar'.tr,
                    icon: Iconsax.add_circle,
                    variant: AppButtonVariant.ghost,
                    onTap: controller.addCar,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
