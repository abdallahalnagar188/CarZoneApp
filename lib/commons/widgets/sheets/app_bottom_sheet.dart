import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;

  const AppBottomSheet({super.key, this.title, required this.child});

  static Future<T?> show<T>({String? title, required Widget child}) {
    return Get.bottomSheet<T>(
      AppBottomSheet(title: title, child: child),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          16.height,
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.headlineSmall),
            12.height,
          ],
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
