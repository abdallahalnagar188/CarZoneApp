import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/utils/system_ui.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../controllers/wash_details_controller.dart';

class GalleryViewerPage extends StatefulWidget {
  const GalleryViewerPage({super.key});

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage> {
  late final PageController _page;
  late int _index;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map? ?? const {};
    _index = args['index'] as int? ?? 0;
    _page = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WashDetailsController>();
    final seed = controller.branch!.photoSeed;
    final count = controller.galleryCount;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _page,
              itemCount: count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Hero(
                    tag: 'gallery_$i',
                    child: AppNetworkImage(
                      photoId: AppNetworkImage.branchPhoto(seed, i),
                      width: 1200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    AppIconButton(glass: true, icon: const Icon(Iconsax.close_circle), onTap: Get.back),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${_index + 1} / $count',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
