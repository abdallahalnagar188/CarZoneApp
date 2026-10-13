import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/system_ui.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/wash_details_controller.dart';
import '../widgets/amenities_wrap.dart';
import '../widgets/book_now_bar.dart';
import '../widgets/next_slots_strip.dart';
import '../widgets/review_tile.dart';
import '../widgets/reviews_summary.dart';
import '../widgets/service_row.dart';
import '../widgets/wash_cover_header.dart';
import '../widgets/wash_gallery_strip.dart';
import '../widgets/wash_info_card.dart';

class WashDetailsPage extends StatelessWidget {
  const WashDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        bottomNavigationBar: const BookNowBar(),
        body: Obx(() {
          if (controller.loading.value || controller.listing.value == null) {
            return const SafeArea(child: AppShimmerList(count: 5));
          }
          return CustomScrollView(
            slivers: [
              const WashCoverHeader(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                sliver: const SliverToBoxAdapter(child: WashInfoCard()),
              ),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.location'.tr)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverToBoxAdapter(
                  child: BranchLocationMap(
                    lat: controller.branch!.lat,
                    lng: controller.branch!.lng,
                    address: controller.branch!.address.value,
                    pinLabel: controller.listing.value!.fromPrice == null
                        ? controller.branch!.name.value
                        : FormatHelper.money(controller.listing.value!.fromPrice!),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.gallery'.tr)),
              const SliverToBoxAdapter(child: WashGalleryStrip()),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.amenities'.tr)),
              const SliverToBoxAdapter(child: AmenitiesWrap()),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.next'.tr)),
              const SliverToBoxAdapter(child: NextSlotsStrip()),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.services'.tr)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverList.list(
                  children: controller.primaries
                      .map((s) => ServiceRow(
                            service: s,
                            offer: controller.offerFor(s),
                            onTap: () => controller.book(serviceId: s.id),
                          ))
                      .toList(),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(title: 'wash.extras'.tr)),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverList.list(
                  children: controller.addons.map((s) => ServiceRow(service: s)).toList(),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'wash.reviews'.tr,
                  actionText: 'wash.seeReviews'.tr,
                  onAction: controller.openReviews,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                sliver: SliverList.list(
                  children: [
                    const ReviewsSummary(),
                    14.height,
                    ...controller.reviews.take(3).map((r) => ReviewTile(review: r)),
                    20.height,
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
