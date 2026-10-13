import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/wash_details_controller.dart';

class WashGalleryStrip extends StatelessWidget {
  const WashGalleryStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final seed = controller.branch!.photoSeed;
    return SizedBox(
      height: 96.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: controller.galleryCount,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => controller.openGallery(i),
          child: Hero(
            tag: 'gallery_$i',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: SizedBox(
                width: 132.w,
                child: AppNetworkImage(photoId: AppNetworkImage.branchPhoto(seed, i), width: 400),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
