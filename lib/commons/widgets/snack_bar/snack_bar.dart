import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/enums/enums.dart';
import '../../../core/extensions/sized_box_extension.dart';

class AppSnackBarContent extends StatelessWidget {
  final String message;
  final TosterTypes type;
  final VoidCallback? onClose;

  const AppSnackBarContent({
    super.key,
    required this.message,
    required this.type,
    this.onClose,
  });

  Color get _baseColor {
    switch (type) {
      case TosterTypes.sucsses:
        return const Color(0xFF0B6BA8);
      case TosterTypes.warning:
        return const Color(0xFFF59E0B);
      case TosterTypes.failed:
        return const Color(0xFFEF4444);
    }
  }

  Color get _iconColor => _baseColor;

  IconData get _statusIcon {
    switch (type) {
      case TosterTypes.sucsses:
        return Iconsax.tick_circle;
      case TosterTypes.warning:
        return Iconsax.info_circle;
      case TosterTypes.failed:
        return Iconsax.close_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 56.h),
      decoration: BoxDecoration(
        color: _baseColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SnackRipplePainter(
                baseColor: _baseColor,
                isRtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: 10.w,
              end: 10.w,
              top: 10.h,
              bottom: 10.h,
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon,
                    size: 20.sp,
                    color: _iconColor,
                  ),
                ),
                12.width,
                Expanded(
                  child: Text(
                    message,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.35,
                        ),
                  ),
                ),
                10.width,
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.close_square,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnackRipplePainter extends CustomPainter {
  final Color baseColor;
  final bool isRtl;

  _SnackRipplePainter({
    required this.baseColor,
    required this.isRtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(
      isRtl ? size.width * 0.9 : size.width * 0.1,
      size.height * 0.5,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.55;

    for (var i = 1; i <= 5; i++) {
      paint.color = Colors.white.withValues(alpha: 0.10 - i * 0.012);
      canvas.drawCircle(origin, size.height * (0.55 + i * 0.72), paint);
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(origin, size.height * 0.85, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SnackRipplePainter oldDelegate) {
    return oldDelegate.baseColor != baseColor || oldDelegate.isRtl != isRtl;
  }
}
