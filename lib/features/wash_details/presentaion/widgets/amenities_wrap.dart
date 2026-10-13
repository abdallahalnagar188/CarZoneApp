import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/wash_details_controller.dart';

class AmenitiesWrap extends StatelessWidget {
  const AmenitiesWrap({super.key});

  static const icons = {
    'waiting': Iconsax.home_hashtag,
    'ac': Iconsax.wind,
    'wifi': Iconsax.wifi,
    'card': Iconsax.card,
    'coffee': Iconsax.coffee,
    'covered': Iconsax.building,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: controller.branch!.amenities
            .map((a) => AppChip(label: 'amenity.$a'.tr, icon: icons[a], flat: true))
            .toList(),
      ),
    );
  }
}
