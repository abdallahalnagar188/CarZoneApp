import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constance/app_colors.dart';

class AppShimmerList extends StatelessWidget {
  final int count;
  final double? itemHeight;

  const AppShimmerList({super.key, this.count = 4, this.itemHeight});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primarySoft,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        padding: EdgeInsets.all(16.r),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, __) => Container(
          height: itemHeight ?? 110.h,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
    );
  }
}
