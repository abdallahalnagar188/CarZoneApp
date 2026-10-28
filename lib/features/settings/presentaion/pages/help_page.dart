import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/services/support_info_service.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final Future<SupportInfo> _info = SupportInfo.load();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppTopBar(title: 'help.title'.tr),
      body: ListView(
        padding: EdgeInsets.all(20.r),
        children: [
          CustomEmptyState(icon: Iconsax.message_question, title: 'help.title'.tr, body: 'help.body'.tr),
          // The fallback shows at once; the settings replace it when they arrive.
          FutureBuilder<SupportInfo>(
            future: _info,
            initialData: SupportInfo.fallback,
            builder: (context, snapshot) {
              final info = snapshot.data ?? SupportInfo.fallback;
              return RoundedContainer(
                child: Column(
                  children: [
                    _Row(
                      icon: Iconsax.call,
                      text: info.phone,
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: info.phone.replaceAll(' ', ''))),
                    ),
                    Divider(color: AppColors.line, height: 24.h),
                    _Row(
                      icon: Iconsax.sms,
                      text: info.email,
                      onTap: () => launchUrl(Uri(scheme: 'mailto', path: info.email)),
                    ),
                    Divider(color: AppColors.line, height: 24.h),
                    _Row(icon: Iconsax.clock, text: info.hours ?? 'help.hours'.tr, ltr: false),
                  ],
                ),
              );
            },
          ),
          28.height,
          Center(child: AppLogo(size: 64.r)),
          10.height,
          Center(child: AppWordmark(height: 14.r, onBrand: AppColors.isDark)),
          8.height,
          Text('app.tagline'.tr, textAlign: TextAlign.center, style: theme.bodySmall),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool ltr;

  const _Row({required this.icon, required this.text, this.onTap, this.ltr = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20.sp),
          12.width,
          Expanded(
            child: Text(
              text,
              textDirection: ltr ? TextDirection.ltr : null,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
