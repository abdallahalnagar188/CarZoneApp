import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constance/app_colors.dart';

class OtpBoxes extends StatefulWidget {
  final TextEditingController controller;
  final bool hasError;
  final VoidCallback? onCompleted;

  const OtpBoxes({
    super.key,
    required this.controller,
    this.hasError = false,
    this.onCompleted,
  });

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final FocusNode _focus = FocusNode();
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(_onFocusChanged);
    _startCursorBlink();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 550), (_) {
      if (mounted && _focus.hasFocus) {
        setState(() => _cursorVisible = !_cursorVisible);
      }
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == 6) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Invisible native textfield for keyboard, paste, and autofill
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 60.h,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            // Modern Styled Pin Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final isFilled = i < text.length;
                final isActive = i == text.length && _focus.hasFocus;

                Color borderColor;
                Color backgroundColor;
                List<BoxShadow>? shadow;

                if (widget.hasError) {
                  borderColor = AppColors.danger;
                  backgroundColor = AppColors.danger.withValues(alpha: 0.05);
                  shadow = [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ];
                } else if (isActive) {
                  borderColor = AppColors.primary;
                  backgroundColor = Colors.white;
                  shadow = [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ];
                } else if (isFilled) {
                  borderColor = AppColors.primary.withValues(alpha: 0.5);
                  backgroundColor = AppColors.primarySoft;
                  shadow = [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ];
                } else {
                  borderColor = AppColors.line;
                  backgroundColor = AppColors.surface;
                  shadow = null;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48.w,
                  height: 60.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: borderColor,
                      width: isActive ? 2.2 : 1.5,
                    ),
                    boxShadow: shadow,
                  ),
                  child: isFilled
                      ? Text(
                          text[i],
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.ink900,
                                fontWeight: FontWeight.w800,
                                fontSize: 22.sp,
                              ),
                        )
                      : (isActive && _cursorVisible
                          ? Container(
                              width: 2.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            )
                          : Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: BoxDecoration(
                                color: AppColors.line,
                                shape: BoxShape.circle,
                              ),
                            )),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
