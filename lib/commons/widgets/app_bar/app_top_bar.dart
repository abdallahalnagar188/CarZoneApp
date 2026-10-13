import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/system_ui.dart';
import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../button/app_icon_button.dart';
import '../icons/dir_icon.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottom;
  final double? bottomHeight;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.bottom,
    this.bottomHeight,
  });

  double get _bottomHeight => bottomHeight ?? 52.h;

  @override
  Size get preferredSize => Size.fromHeight(64.h + (bottom == null ? 12.h : _bottomHeight + 16.h));

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (onBack != null || Navigator.of(context).canPop());
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
          boxShadow: AppColors.liftShadow,
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    if (canPop)
                      AppIconButton(
                        glass: true,
                        icon: const DirIcon(Iconsax.arrow_left_2),
                        onTap: onBack ?? Get.back,
                      )
                    else
                      SizedBox(width: 42.r),
                    12.width,
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 17.sp,
                            ),
                      ),
                    ),
                    12.width,
                    if (actions.isEmpty)
                      SizedBox(width: 42.r)
                    else
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                child: SizedBox(height: _bottomHeight, child: bottom),
              )
            else
              8.height,
          ],
        ),
      ),
    );
  }
}
