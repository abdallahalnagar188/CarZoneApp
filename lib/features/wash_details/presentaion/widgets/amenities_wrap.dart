import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/wash_details_controller.dart';

class AmenitiesWrap extends StatelessWidget {
  const AmenitiesWrap({super.key});

  static const icons = {
    'waiting': Iconsax.home_hashtag,
    'ac': Iconsax.wind,
    'wifi': Iconsax.wifi,
    'card': Iconsax.card,
    'coffee': Iconsax.coffee,
    'covered': Iconsax.building,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final branch = controller.branch!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: branch.amenities
            .map((a) => AppChip(label: _label(a, branch.amenityNames[a]?.value), icon: icons[a], flat: true))
            .toList(),
      ),
    );
  }

  /// The built-in wording for the known amenities, else the name the platform gave it.
  static String _label(String id, String? dbName) {
    final key = 'amenity.$id';
    final built = key.tr;
    if (built != key) return built;
    return (dbName == null || dbName.isEmpty) ? id : dbName;
  }
}
