import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/services/connectivity_service.dart';

/// Shows a strip above the whole app while the backend is unreachable, and a
/// short "back online" note when the connection returns. The strip takes the
/// status bar area, so the page below it loses its top padding meanwhile.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Worker? _worker;
  Timer? _hideTimer;
  bool _offline = false;
  bool _backOnline = false;

  @override
  void initState() {
    super.initState();
    final connectivity = ConnectivityService.maybe;
    if (connectivity == null) return;
    _offline = !connectivity.isOnline.value;
    _worker = ever<bool>(connectivity.isOnline, _onChanged);
  }

  void _onChanged(bool online) {
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() {
      _backOnline = online && _offline;
      _offline = !online;
    });
    if (_backOnline) {
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _backOnline = false);
      });
    }
  }

  @override
  void dispose() {
    _worker?.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _offline || _backOnline;
    final topPadding = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: visible
              ? Material(
                  color: _offline ? AppColors.danger : AppColors.success,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, topPadding + 6.h, 16.w, 8.h),
                    child: Row(
                      children: [
                        Icon(
                          _offline ? Iconsax.wifi_square : Iconsax.tick_circle,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            (_offline ? 'offline.banner' : 'offline.back').tr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
