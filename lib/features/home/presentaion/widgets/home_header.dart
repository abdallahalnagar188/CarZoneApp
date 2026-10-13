import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';
import 'home_search_bar.dart';

class HomeSliverHeader extends SliverPersistentHeaderDelegate {
  final double topPadding;

  HomeSliverHeader({required this.topPadding});

  double get _rowTop => topPadding + 10.h;
  double get _rowHeight => 46.r;
  double get _searchHeight => 60.h;
  double get _greetingHeight => 62.h;

  @override
  double get maxExtent => _rowTop + _rowHeight + 16.h + _greetingHeight + 14.h + _searchHeight;

  @override
  double get minExtent => _rowTop + _rowHeight + 14.h;

  @override
  bool shouldRebuild(covariant HomeSliverHeader oldDelegate) => oldDelegate.topPadding != topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final extent = math.max(minExtent, maxExtent - shrinkOffset);
    final gradientHeight = extent - (_searchHeight / 2) * (1 - t);
    final greetingOpacity = (1 - t * 1.8).clamp(0.0, 1.0);
    final searchOpacity = (1 - t * 2.4).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: gradientHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34.r - 8.r * t)),
              boxShadow: t > 0.95 ? AppColors.liftShadow : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -60.w,
                  top: -30.h - 40.h * t,
                  child: Opacity(opacity: 1 - t * 0.6, child: _Bubble(size: 190.r)),
                ),
                PositionedDirectional(
                  end: 120.w,
                  bottom: 30.h,
                  child: Opacity(opacity: greetingOpacity, child: _Bubble(size: 56.r)),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: _rowTop + _rowHeight + 16.h - 30.h * t,
          start: 20.w,
          end: 20.w,
          child: IgnorePointer(
            child: Opacity(
              opacity: greetingOpacity,
              child: Transform.scale(
                scale: 1 - 0.08 * t,
                alignment: AlignmentDirectional.topStart,
                child: const _Greeting(),
              ),
            ),
          ),
        ),
        if (searchOpacity > 0)
          PositionedDirectional(
            start: 20.w,
            end: 20.w,
            bottom: 0,
            height: _searchHeight,
            child: IgnorePointer(
              ignoring: searchOpacity < 0.3,
              child: Opacity(
                opacity: searchOpacity,
                child: Transform.scale(
                  scale: 1 - 0.1 * (1 - searchOpacity),
                  child: const HomeSearchBar(),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          top: _rowTop,
          start: 20.w,
          end: 20.w,
          height: _rowHeight,
          child: const _TopRow(),
        ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final user = controller.session.user.value;
      return Row(
        children: [
          GestureDetector(
            onTap: controller.pickArea,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.location, size: 16.sp, color: Colors.white),
                  6.width,
                  Text(controller.session.area.name.value, style: theme.labelLarge?.copyWith(color: Colors.white)),
                  4.width,
                  Icon(Iconsax.arrow_down_1, size: 14.sp, color: Colors.white),
                ],
              ),
            ),
          ),
          const Spacer(),
          AppIconButton(
            glass: true,
            badge: controller.unread.value,
            icon: const Icon(Iconsax.notification),
            onTap: controller.openNotifications,
          ),
          10.width,
          GestureDetector(
            onTap: controller.openProfile,
            child: InitialsAvatar(name: user?.name, size: 42.r, sand: true),
          ),
        ],
      );
    });
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return Obx(() {
      final user = controller.session.user.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user == null ? 'greet.guest'.tr : 'greet.user'.trParams({'name': user.firstName}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.headlineLarge?.copyWith(color: Colors.white),
          ),
          4.height,
          Text(
            'app.tagline'.tr,
            style: theme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ],
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  final double size;

  const _Bubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
    );
  }
}
