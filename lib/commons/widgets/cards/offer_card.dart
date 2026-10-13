import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_assets.dart';
import '../../../core/constance/app_colors.dart';
import '../../../core/enums/enums.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../../core/helpers/format_helper.dart';
import '../../models/offer_model.dart';
import '../images/app_network_image.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final String washName;
  final VoidCallback? onTap;
  final double? width;

  const OfferCard({
    super.key,
    required this.offer,
    required this.washName,
    this.onTap,
    this.width,
  });

  String get _badge => offer.discountType == DiscountType.percent
      ? '${offer.discountValue}%'
      : FormatHelper.money(offer.discountValue);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final days = offer.endAt.difference(DateTime.now()).inDays;
    final ends = days <= 0 ? 'offers.ends1'.tr : 'offers.ends'.trParams({'n': '$days'});
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 168.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: AppColors.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(photoId: AppRes.offers[offer.photoIndex % AppRes.offers.length], width: 700),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [
                    AppColors.brandNight.withValues(alpha: 0.92),
                    AppColors.brand.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'offers.off'.trParams({'v': _badge}),
                    style: theme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  2.height,
                  Text(
                    offer.title.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall?.copyWith(color: Colors.white),
                  ),
                  Text(
                    washName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.timer_1, size: 13.sp, color: Colors.white),
                        6.width,
                        Text(ends, style: theme.labelSmall?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
