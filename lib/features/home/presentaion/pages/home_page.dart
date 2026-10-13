import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/system_ui.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_header.dart';
import '../widgets/home_prompt_cards.dart';
import '../widgets/map_preview_card.dart';
import '../widgets/nearby_washes_list.dart';
import '../widgets/offers_carousel.dart';
import '../widgets/service_categories_grid.dart';
import '../widgets/wash_now_hero.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Widget _enter(int index, Widget child) => FadeSlideIn(
        delay: Duration(milliseconds: 80 * index),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final header = HomeSliverHeader(topPadding: MediaQuery.paddingOf(context).top);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: RefreshIndicator(
        onRefresh: controller.load,
        edgeOffset: header.minExtent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPersistentHeader(pinned: true, delegate: header),
            SliverToBoxAdapter(child: 20.height),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _enter(0, const WashNowHero()),
                    _enter(1, const HomePromptCards()),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _enter(2, SectionHeader(title: 'home.services'.tr))),
            SliverToBoxAdapter(child: _enter(3, const ServiceCategoriesGrid())),
            SliverToBoxAdapter(
              child: _enter(
                4,
                SectionHeader(
                  title: 'home.nearby'.tr,
                  actionText: 'home.seeAll'.tr,
                  onAction: controller.openNearby,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(
                () => controller.loading.value
                    ? SizedBox(height: 252.h, child: const AppShimmerList(count: 1, itemHeight: 230))
                    : _enter(0, const NearbyWashesList()),
              ),
            ),
            SliverToBoxAdapter(
              child: _enter(
                5,
                SectionHeader(
                  title: 'home.offers'.tr,
                  actionText: 'home.seeAll'.tr,
                  onAction: controller.openOffers,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _enter(6, const OffersCarousel())),
            SliverToBoxAdapter(child: 24.height),
            SliverToBoxAdapter(child: _enter(7, const MapPreviewCard())),
            SliverToBoxAdapter(child: 130.height),
          ],
        ),
      ),
    );
  }
}
