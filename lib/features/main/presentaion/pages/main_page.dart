import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../bookings/presentaion/pages/bookings_page.dart';
import '../../../home/presentaion/pages/home_page.dart';
import '../../../map/presentaion/pages/map_page.dart';
import '../../../profile/presentaion/pages/profile_page.dart';
import '../controllers/main_controller.dart';
import '../widgets/app_bottom_nav.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Scaffold(
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: const [
            HomePage(),
            MapPage(),
            BookingsPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
