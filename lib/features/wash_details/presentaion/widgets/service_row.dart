import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/offer_model.dart';
import '../../../../commons/models/wash_service_model.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class ServiceRow extends StatelessWidget {
  final WashServiceModel service;
  final OfferModel? offer;
  final VoidCallback? onTap;

  const ServiceRow({super.key, required this.service, this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name.value, style: theme.titleMedium),
                  2.height,
                  Text(service.description.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.bodySmall),
                  if (offer != null) ...[
                    6.height,
                    Text(
                      'book.offer'.trParams({'v': offer!.offerLabel}),
                      style: theme.labelMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            10.width,
            Text(
              FormatHelper.money(service.price),
              style: theme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
            10.width,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                FormatHelper.minutes(service.durationMin),
                style: theme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
