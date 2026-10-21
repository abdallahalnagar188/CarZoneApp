import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../controllers/main_controller.dart';

/// Floating liquid-glass tab bar (same style as the Qhub app): a frosted
/// capsule with the four tabs and a sliding selection pill, next to a round
/// "wash now" button.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const _items = [
    (Iconsax.home_2, 'nav.home'),
    (Iconsax.map, 'nav.map'),
    (Iconsax.calendar_1, 'nav.bookings'),
    (Iconsax.user, 'nav.profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    final height = 64.h.clamp(58.0, 76.0).toDouble();

    // Floats over the content; Scaffold.extendBody lets pages scroll beneath it.
    // Sits just slightly into the home-indicator area instead of fully above it.
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = math.max(safeBottom - 4.h, 18.h);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Expanded(
              child: _GlassCapsule(
                height: height,
                child: Obx(() {
                  final selected = controller.selectedIndex.value;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / _items.length;
                      return Stack(
                        children: [
                          _LiquidPill(position: selected, itemWidth: itemWidth),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < _items.length; i++)
                                _NavItem(
                                  icon: _items[i].$1,
                                  label: _items[i].$2.tr,
                                  isSelected: selected == i,
                                  onTap: () => _select(controller, i),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
            SizedBox(width: 10.w),
            _WashNowButton(size: height, onTap: controller.openWashNow),
          ],
        ),
      ),
    );
  }

  void _select(MainController controller, int index) {
    if (controller.selectedIndex.value != index) HapticFeedback.selectionClick();
    controller.changeTab(index);
  }
}

/// Frosted capsule: the content behind stays visible through a light blur
/// with boosted color (vibrancy), a sheen on the top half, a soft double
/// shadow and a bright rim that fades along the edge.
class _GlassCapsule extends StatelessWidget {
  final double height;
  final Widget child;

  const _GlassCapsule({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final radius = BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: _floatingShadow(isDark)),
      foregroundDecoration: _GlassRimDecoration(radius: radius, isDark: isDark),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            inner: ColorFilter.matrix(_saturation(1.8)),
          ),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.5, 1],
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.16),
                        AppColors.surface.withValues(alpha: 0.70),
                        AppColors.surface.withValues(alpha: 0.80),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.74),
                        Colors.white.withValues(alpha: 0.80),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _floatingShadow(bool isDark) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ];

Color get _selectedPillColor =>
    AppColors.primary.withValues(alpha: AppColors.isDark ? 0.26 : 0.15);

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  // Icon "pop" when the tab becomes selected (Qhub plays a Lottie here).
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.14), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 40),
  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.primary : AppColors.ink700;

    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(widget.icon, size: 22.w, color: color),
                ),
                SizedBox(height: 3.h),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        fontSize: 11.sp,
                        fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                        height: 1.1,
                      ),
                  child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected-tab pill: slides to the new tab and stretches a little
/// mid-way, then settles.
class _LiquidPill extends StatefulWidget {
  final int position;
  final double itemWidth;

  const _LiquidPill({required this.position, required this.itemWidth});

  @override
  State<_LiquidPill> createState() => _LiquidPillState();
}

class _LiquidPillState extends State<_LiquidPill> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );
  late double _from = widget.position.toDouble();

  @override
  void didUpdateWidget(_LiquidPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      // Start from wherever the pill is now, even mid-animation.
      _from = _currentPosition(oldWidget.position);
      _controller.forward(from: 0);
    }
  }

  double _currentPosition(int target) {
    final t = Curves.easeOutCubic.transform(_controller.value);
    return _from + (target - _from) * t;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final position = _currentPosition(widget.position);
        final stretch = widget.itemWidth * 0.22 * math.sin(math.pi * _controller.value);
        // Directional, so the pill follows the tabs in both RTL and LTR.
        return PositionedDirectional(
          start: position * widget.itemWidth - stretch / 2,
          top: 0,
          bottom: 0,
          width: widget.itemWidth + stretch,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _selectedPillColor,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      },
    );
  }
}

/// Round primary button beside the capsule, with the same rim and shadow.
class _WashNowButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _WashNowButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final radius = BorderRadius.circular(size / 2);

    return Semantics(
      button: true,
      label: 'nav.wash_now'.tr,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: radius,
            boxShadow: [
              ..._floatingShadow(isDark),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          foregroundDecoration: _GlassRimDecoration(radius: radius, isDark: isDark),
          child: Icon(Iconsax.magic_star, color: Colors.white, size: 24.w),
        ),
      ),
    );
  }
}

/// Saturation color matrix (1 = unchanged) used for the glass vibrancy.
List<double> _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return [
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0, //
    r * i, g * i, b * i + s, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// Glass rim: a 1px stroke whose brightness changes around the edge
/// (bright at the top and bottom-end, faint on the sides), like light
/// catching the edge of liquid glass.
class _GlassRimDecoration extends Decoration {
  final BorderRadius radius;
  final bool isDark;

  const _GlassRimDecoration({required this.radius, required this.isDark});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GlassRimPainter(radius, isDark);
}

class _GlassRimPainter extends BoxPainter {
  final BorderRadius radius;
  final bool isDark;

  _GlassRimPainter(this.radius, this.isDark);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = (offset & size).deflate(0.5);
    final strong = Colors.white.withValues(alpha: isDark ? 0.35 : 1);
    final faint = Colors.white.withValues(alpha: isDark ? 0.06 : 0.35);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [strong, faint, faint, strong],
        stops: const [0, 0.35, 0.65, 1],
      ).createShader(rect);
    canvas.drawRRect(radius.toRRect(rect), paint);
  }
}
