import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/presentaion/pages/bookings_page.dart';
import '../../../home/presentaion/pages/home_page.dart';
import '../../../map/presentaion/pages/map_page.dart';
import '../../../profile/presentaion/pages/profile_page.dart';
import '../controllers/main_provider.dart';
import '../widgets/app_bottom_nav.dart';

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainNavIndexProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          HomePage(),
          MapPage(),
          BookingsPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
