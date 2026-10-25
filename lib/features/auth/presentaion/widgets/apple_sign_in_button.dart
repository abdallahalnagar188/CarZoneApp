import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/extensions/sized_box_extension.dart';

/// Black "Continue with Apple" button, sized like [GoogleSignInButton] and
/// following Apple's Sign in with Apple button guidelines.
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;

  const AppleSignInButton({
    super.key,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          height: 52.h,
          width: double.infinity,
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.white, size: 24.r),
                    10.width,
                    Text(
                      'login.apple'.tr,
                      style: theme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
