import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool dense;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.dense = false,
  });

  OutlineInputBorder _border(Color color, [double width = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: theme.titleSmall),
          8.height,
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          autofocus: autofocus,
          textAlign: textAlign,
          textDirection: textDirection,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: theme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.bodyMedium?.copyWith(color: AppColors.hintGray),
            filled: true,
            fillColor: AppColors.surface,
            counterText: '',
            prefixIcon: prefix,
            suffixIcon: suffix,
            isDense: dense,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: dense ? 12.h : 16.h),
            enabledBorder: _border(error != null ? AppColors.danger : AppColors.line),
            focusedBorder: _border(error != null ? AppColors.danger : AppColors.primary, 1.8),
            border: _border(AppColors.line),
          ),
        ),
        if (error != null) ...[
          6.height,
          Text(error!, style: theme.bodySmall?.copyWith(color: AppColors.danger)),
        ],
      ],
    );
  }
}
