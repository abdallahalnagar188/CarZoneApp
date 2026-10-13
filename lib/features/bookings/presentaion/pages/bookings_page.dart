import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../controllers/bookings_controller.dart';
import '../widgets/booking_card.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingsController>();
    return Scaffold(
      appBar: AppTopBar(
        title: 'bookings.title'.tr,
        showBack: false,
        bottom: Obx(() => _Tabs(index: controller.tab.value, onChanged: controller.setTab)),
      ),
      body: Obx(() {
        if (!controller.session.isLoggedIn) {
          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [GuestLoginCard(onTap: controller.login)],
          );
        }
        final list = controller.tab.value == 0 ? controller.upcoming : controller.history;
        if (controller.loading.value) return const AppShimmerList();
        if (list.isEmpty) {
          return Center(
            child: CustomEmptyState(
              icon: Iconsax.calendar_remove,
              title: 'empty.bookings'.tr,
              actionText: 'empty.bookCta'.tr,
              onAction: controller.bookWash,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 130.h),
            children: list
                .map((o) => BookingCard(
                      order: o,
                      branchName: controller.branchName(o),
                      onTap: () => controller.open(o),
                    ))
                .toList(),
          ),
        );
      }),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _Tabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['bookings.upcoming'.tr, 'bookings.history'.tr];
    return Container(
      height: 46.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: List.generate(2, (i) {
          final on = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  labels[i],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: on ? AppColors.brand : Colors.white,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
