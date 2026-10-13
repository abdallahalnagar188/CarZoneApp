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
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == 6) widget.onCompleted?.call();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return GestureDetector(
      onTap: () => _focus.requestFocus(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 58.h,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final filled = i < text.length;
                final active = i == text.length && _focus.hasFocus;
                final border = widget.hasError
                    ? AppColors.danger
                    : active || filled
                        ? AppColors.primary
                        : AppColors.line;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48.w,
                  height: 58.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primarySoft : AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: border, width: active ? 2 : 1.5),
                  ),
                  child: Text(
                    filled ? text[i] : '',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.ink900),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
