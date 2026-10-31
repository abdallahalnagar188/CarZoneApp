import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/icons/dir_icon.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/onboarding_provider.dart';

class OnboardingFooter extends ConsumerWidget {
  const OnboardingFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final last = notifier.isLast;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 20.h),
        child: Row(
          children: [
            Row(
              children: List.generate(OnboardingNotifier.count, (d) {
                final on = d == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  margin: EdgeInsetsDirectional.only(end: 6.w),
                  width: on ? 26.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    gradient: on ? AppColors.ribbonGradient : null,
                    color: on ? null : AppColors.primarySoft2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => notifier.next(ref),
              child: SizedBox(
                height: 68.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!last)
                      SizedBox(
                        width: 68.r,
                        height: 68.r,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (i + 1) / OnboardingNotifier.count),
                          duration: const Duration(milliseconds: 380),
                          builder: (_, v, __) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 3,
                            backgroundColor: AppColors.primarySoft2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 54.r,
                      padding: EdgeInsets.symmetric(horizontal: last ? 22.w : 0),
                      constraints: BoxConstraints(minWidth: 54.r),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: AppColors.buttonShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (last) ...[
                            Text(
                              'onb.start'.tr,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 15.sp),
                            ),
                            10.width,
                          ],
                          DirIcon(Iconsax.arrow_right_3, color: Colors.white, size: 22.sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
