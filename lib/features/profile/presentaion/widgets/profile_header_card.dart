import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/customer_model.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class ProfileHeaderCard extends StatelessWidget {
  final CustomerModel user;
  final VoidCallback onEdit;

  const ProfileHeaderCard({super.key, required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: AppColors.liftShadow,
      ),
      child: Row(
        children: [
          InitialsAvatar(name: user.name, size: 62.r, sand: true),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: theme.titleLarge?.copyWith(color: Colors.white)),
                4.height,
                Text(
                  user.phone,
                  textDirection: TextDirection.ltr,
                  style: theme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          AppIconButton(glass: true, icon: const Icon(Iconsax.edit_2), onTap: onEdit),
        ],
      ),
    );
  }
}
