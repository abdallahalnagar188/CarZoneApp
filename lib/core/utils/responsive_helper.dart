import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const Size designSize = Size(393, 852);
  static const double maxScaleWidth = 600;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = widthOf(context);
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= desktopBreakpoint;

  static bool isWide(BuildContext context) =>
      widthOf(context) >= mobileBreakpoint;

  static bool isCompact(BuildContext context) => isMobile(context);

  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: isMobile(context) ? 16.w : 32.w,
      vertical: isMobile(context) ? 14.h : 24.h,
    );
  }

  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: isMobile(context) ? 16.w : 32.w);
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double fontSizeMultiplier(BuildContext context) {
    if (isDesktop(context)) return 1.2;
    if (isTablet(context)) return 1.1;
    return 1.0;
  }

  static double spacing(BuildContext context, double mobileSpacing) {
    return isMobile(context) ? mobileSpacing : mobileSpacing * 1.5;
  }

  static double maxContentWidth(BuildContext context) {
    return double.infinity;
  }

  static double chatContentWidth(BuildContext context) {
    return double.infinity;
  }

  static double dialogWidth(BuildContext context) {
    final screenWidth = widthOf(context);
    if (isDesktop(context)) return math.min(screenWidth * 0.4, 480);
    if (isTablet(context)) return math.min(screenWidth * 0.6, 420);
    return screenWidth * 0.9;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  static double bottomSheetHeight(BuildContext context) {
    final screenHeight = heightOf(context);
    if (isWide(context)) return screenHeight * 0.6;
    return screenHeight * 0.9;
  }

  static int listGridColumns(BuildContext context) {
    final width = widthOf(context);
    if (width >= 1100) return 2;
    if (width >= mobileBreakpoint) return 2;
    return 1;
  }

  static double cardAspectRatio(BuildContext context) {
    if (isWide(context)) return 2.4;
    return 1.4;
  }

  static double listCardExtent(BuildContext context) {
    if (isWide(context)) return 120;
    return 100;
  }

  static double formMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 560;
    if (isTablet(context)) return 520;
    return double.infinity;
  }

  static double navMaxWidth(BuildContext context) {
    return double.infinity;
  }

  static double sheetMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 640;
    if (isTablet(context)) return 560;
    return double.infinity;
  }

  static double readingMaxWidth(BuildContext context) {
    if (isWide(context)) return 720;
    return double.infinity;
  }

  static double bubbleMaxWidth(
    BuildContext context, {
    double fraction = 0.72,
    double wideCap = 420,
  }) {
    final screenWidth = widthOf(context);
    final fractionWidth = screenWidth * fraction;
    if (isWide(context)) return math.min(fractionWidth, wideCap);
    return fractionWidth;
  }

  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 48;
    if (isTablet(context)) return 32;
    return 20;
  }

  static EdgeInsets cardPadding(BuildContext context) {
    if (isWide(context)) {
      return EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);
    }
    return EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h);
  }

  static EdgeInsets contentSideInsets(
    BuildContext context, {
    double extra = 0,
    double? maxWidth,
  }) {
    final width = widthOf(context);
    final base = horizontalPadding(context);
    final cap = maxWidth ?? maxContentWidth(context);
    if (!cap.isFinite) {
      return EdgeInsets.symmetric(horizontal: extra > 0 ? extra : base);
    }
    final side = math.max(base, (width - cap) / 2) + extra;
    return EdgeInsets.symmetric(horizontal: side);
  }

  static void configureClampedScreenUtil(BuildContext context) {
    final view = View.maybeOf(context);
    if (view == null) return;

    final data = MediaQueryData.fromView(view);
    final cappedWidth = math.min(data.size.width, maxScaleWidth);
    final cappedHeight = math.min(
      data.size.height,
      designSize.height * (maxScaleWidth / designSize.width),
    );

    ScreenUtil.configure(
      data: data.copyWith(size: Size(cappedWidth, cappedHeight)),
      designSize: designSize,
      splitScreenMode: true,
      minTextAdapt: true,
    );
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveHelper.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth(context),
          minWidth: 0,
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

class ResponsivePageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ResponsivePageBody({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth(context),
      padding: padding,
      child: child,
    );
  }
}

class ResponsiveSheetBody extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const ResponsiveSheetBody({
    super.key,
    required this.child,
    this.maxHeight,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final sheetWidth = maxWidth ?? ResponsiveHelper.sheetMaxWidth(context);
    final sheetHeight =
        maxHeight ?? ResponsiveHelper.bottomSheetHeight(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: sheetWidth,
                maxHeight: sheetHeight,
                minWidth: 0,
              ),
              child: Material(
                color: backgroundColor ?? Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior:
                    borderRadius != null ? Clip.antiAlias : Clip.none,
                child: padding == null
                    ? child
                    : Padding(padding: padding!, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
