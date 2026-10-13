import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_menu_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppTopBar(title: 'profile.title'.tr, showBack: false),
      body: Obx(() {
        final user = controller.session.user.value;
        return ListView(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 130.h),
          children: [
            if (user == null)
              GuestLoginCard(onTap: controller.login)
            else
              ProfileHeaderCard(user: user, onEdit: controller.openEdit),
            20.height,
            RoundedContainer(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Column(
                children: [
                  if (user != null) ...[
                    ProfileMenuTile(icon: Iconsax.car, title: 'profile.cars'.tr, onTap: controller.openCars),
                    ProfileMenuTile(icon: Iconsax.calendar_1, title: 'profile.bookings'.tr, onTap: controller.openBookings),
                    ProfileMenuTile(icon: Iconsax.heart, title: 'profile.fav'.tr, onTap: controller.openFavorites),
                    ProfileMenuTile(
                      icon: Iconsax.notification,
                      title: 'profile.notif'.tr,
                      badge: controller.unread,
                      onTap: controller.openNotifications,
                    ),
                  ],
                  ProfileMenuTile(icon: Iconsax.setting_2, title: 'profile.lang'.tr, onTap: controller.openSettings),
                  ProfileMenuTile(icon: Iconsax.shield_tick, title: 'profile.legal'.tr, onTap: controller.openLegal),
                  ProfileMenuTile(icon: Iconsax.message_question, title: 'profile.help'.tr, onTap: controller.openHelp),
                ],
              ),
            ),
            if (user != null) ...[
              14.height,
              RoundedContainer(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: ProfileMenuTile(
                  icon: Iconsax.logout,
                  title: 'profile.logout'.tr,
                  danger: true,
                  onTap: controller.logout,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
