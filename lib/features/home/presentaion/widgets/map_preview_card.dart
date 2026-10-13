import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../controllers/home_controller.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: controller.openMap,
        child: Container(
          height: 150.h,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: AppColors.liftShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              _pin(0.12, 0.18, 22),
              _pin(0.34, 0.32, 26),
              _pin(0.72, 0.22, 30),
              Positioned(
                left: 0,
                right: 0,
                top: 50.h,
                child: Center(
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glow.withValues(alpha: 0.25),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 14.r,
                      height: 14.r,
                      decoration: BoxDecoration(
                        color: AppColors.glow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 18.w,
                end: 18.w,
                bottom: 16.h,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'home.map'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: DirIcon(Iconsax.arrow_right_3, color: AppColors.brand, size: 20.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pin(double x, double y, double size) {
    return Positioned.fill(
      child: Align(
        alignment: FractionalOffset(x, y),
        child: Icon(Iconsax.location5, size: size.sp, color: Colors.white),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    for (var x = -size.height; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * 0.6, 0), paint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 24), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
