import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/extensions/sized_box_extension.dart';
import '../button/app_button.dart';

/// Which maps app gives the directions. Apple Maps comes first on iOS.
enum MapsApp { apple, google }

class DirectionsSheet extends StatelessWidget {
  const DirectionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          title: 'maps.apple'.tr,
          icon: Iconsax.map_1,
          onTap: () => Get.back(result: MapsApp.apple),
        ),
        10.height,
        AppButton(
          title: 'maps.google'.tr,
          icon: Iconsax.location,
          variant: AppButtonVariant.ghost,
          onTap: () => Get.back(result: MapsApp.google),
        ),
      ],
    );
  }
}
