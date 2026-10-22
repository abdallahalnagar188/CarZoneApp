import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'binding/app_binding.dart';
import 'commons/widgets/connectivity/offline_banner.dart';
import 'commons/styles/themes/app_theme.dart';
import 'core/local/app_translation.dart';
import 'core/local/lang_controller.dart';
import 'core/local/theme_controller.dart';
import 'core/routing/app_routes.dart';
import 'core/utils/responsive_helper.dart';
import 'core/utils/system_ui.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return ScreenUtilInit(
      designSize: ResponsiveHelper.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        ResponsiveHelper.configureClampedScreenUtil(context);
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: GetMaterialApp(
            title: 'CarZone',
            debugShowCheckedModeBanner: false,
            theme: MyAppTheme.lightTheme,
            darkTheme: MyAppTheme.darkTheme,
            themeMode: themeController.themeMode,
            translations: AppTranslations(),
            locale: LanguageGetxController.cachedLocale,
            fallbackLocale: const Locale(LanguageGetxController.defaultLang),
            initialBinding: AppBinding(),
            getPages: appPages,
            initialRoute: Routes.splashRoute,
            builder: (context, child) {
              ResponsiveHelper.configureClampedScreenUtil(context);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUi.adaptive,
                child: OfflineBanner(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        );
      },
    );
  }
}
