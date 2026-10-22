import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';

/// Home entry to the map tab: a drawn street map with wash pins, the user's
/// pulsing location and a frosted bar with the nearby count.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key});

  // Pins and the user dot as fractions of the map area.
  static const _pins = [Offset(0.16, 0.22), Offset(0.42, 0.14), Offset(0.78, 0.30), Offset(0.62, 0.52)];
  static const _me = Offset(0.32, 0.50);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: controller.openMap,
        child: Container(
          height: 196.h,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(color: AppColors.line),
            boxShadow: AppColors.softShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, box) {
              Offset at(Offset f) => Offset(f.dx * box.maxWidth, f.dy * box.maxHeight);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapPainter(
                        dark: AppColors.isDark,
                        me: at(_me),
                        target: at(_pins[3]),
                      ),
                    ),
                  ),
                  for (var i = 0; i < _pins.length; i++) _placed(at(_pins[i]), _WashPin(highlighted: i == 3)),
                  _placed(at(_me), const _MyLocation()),
                  PositionedDirectional(
                    start: 10.w,
                    end: 10.w,
                    bottom: 10.h,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: EdgeInsetsDirectional.fromSTEB(10.w, 10.h, 10.w, 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: AppColors.surface.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Iconsax.map_1, color: AppColors.primary, size: 20.sp),
                              ),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'home.map'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.titleMedium?.copyWith(color: AppColors.ink900),
                                    ),
                                    Obx(() {
                                      final count = controller.nearby.length;
                                      return Text(
                                        count == 0
                                            ? 'home.mapExplore'.tr
                                            : 'home.mapCount'.trParams({'count': '$count'}),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.bodySmall?.copyWith(color: AppColors.ink500),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              8.width,
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.buttonShadow,
                                ),
                                child: DirIcon(Iconsax.arrow_right_3, color: Colors.white, size: 18.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Centers [child] on [point].
  static Widget _placed(Offset point, Widget child) => Positioned(
        left: point.dx,
        top: point.dy,
        child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
      );
}

class _WashPin extends StatelessWidget {
  final bool highlighted;

  const _WashPin({this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final size = highlighted ? 34.r : 28.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: highlighted ? AppColors.primaryGradient : null,
        color: highlighted ? null : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: highlighted ? Colors.white : AppColors.primarySoft2, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: highlighted ? 0.3 : 0.15),
            blurRadius: highlighted ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Iconsax.car5, size: size * 0.48, color: highlighted ? Colors.white : AppColors.primary),
    );
  }
}

/// The user's location: a solid dot with a slow pulse ring.
class _MyLocation extends StatefulWidget {
  const _MyLocation();

  @override
  State<_MyLocation> createState() => _MyLocationState();
}

class _MyLocationState extends State<_MyLocation> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = 46.r;
    return SizedBox(
      width: ring,
      height: ring,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: ring * (0.4 + 0.6 * _pulse.value),
              height: ring * (0.4 + 0.6 * _pulse.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandCyan.withValues(alpha: 0.35 * (1 - _pulse.value)),
              ),
            ),
            child!,
          ],
        ),
        child: Container(
          width: 16.r,
          height: 16.r,
          decoration: BoxDecoration(
            color: AppColors.brandSky,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: AppColors.brandSky.withValues(alpha: 0.5), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

/// Stylised streets, a park and a river, plus a dashed route from the user
/// to the highlighted wash.
class _MapPainter extends CustomPainter {
  final bool dark;
  final Offset me;
  final Offset target;

  _MapPainter({required this.dark, required this.me, required this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = dark ? const Color(0xFF0D1B33) : const Color(0xFFEEF4FB));

    // Park and river give the map some landmarks.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.52, h * 0.04, w * 0.2, h * 0.3), const Radius.circular(14)),
      Paint()..color = dark ? const Color(0xFF12304A) : const Color(0xFFDCEFE6),
    );
    final river = Path()
      ..moveTo(w * 0.86, -10)
      ..cubicTo(w * 0.8, h * 0.3, w * 0.98, h * 0.55, w * 0.9, h + 10);
    canvas.drawPath(
      river,
      Paint()
        ..color = AppColors.brandCyan.withValues(alpha: dark ? 0.22 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );

    final road = Paint()
      ..color = dark ? const Color(0xFF1C3150) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    road.strokeWidth = 6;
    for (final y in [0.18, 0.42, 0.7]) {
      canvas.drawLine(Offset(-10, h * y), Offset(w + 10, h * (y + 0.06)), road);
    }
    for (final x in [0.08, 0.3, 0.5, 0.7]) {
      canvas.drawLine(Offset(w * x, -10), Offset(w * (x + 0.08), h + 10), road);
    }
    // Main avenue.
    canvas.drawLine(Offset(-10, h * 0.86), Offset(w + 10, h * 0.2), road..strokeWidth = 12);

    // Dashed route from the user to the highlighted wash.
    final route = Path()
      ..moveTo(me.dx, me.dy)
      ..quadraticBezierTo((me.dx + target.dx) / 2, me.dy + h * 0.22, target.dx, target.dy);
    final dash = Paint()
      ..shader = AppColors.ribbonGradient.createShader(Rect.fromPoints(me, target), textDirection: TextDirection.ltr)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, (d + 6).clamp(0, metric.length)), dash);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.dark != dark || old.me != me || old.target != target;
}
