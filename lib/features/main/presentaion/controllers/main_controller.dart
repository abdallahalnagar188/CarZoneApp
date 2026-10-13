import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';

class MainController extends GetxController {
  final selectedIndex = 0.obs;

  void changeTab(int index) => selectedIndex.value = index;

  void openWashNow() => Get.toNamed(Routes.resultsRoute, arguments: {'mode': 'washnow'});
}
