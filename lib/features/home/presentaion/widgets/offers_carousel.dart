import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/home_controller.dart';

class OffersCarousel extends StatelessWidget {
  const OffersCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return SizedBox(
      height: 172.h,
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
          itemCount: controller.offers.length,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, i) {
            final offer = controller.offers[i];
            return OfferCard(
              width: 300.w,
              offer: offer,
              washName: controller.offerWashName(offer),
              onTap: () => controller.openOffer(offer),
            );
          },
        ),
      ),
    );
  }
}
