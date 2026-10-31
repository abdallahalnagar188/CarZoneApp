import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'commons/styles/themes/app_theme.dart';
import 'commons/widgets/connectivity/offline_banner.dart';
import 'core/local/locale_provider.dart';
import 'core/local/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/routing/navigator_keys.dart';
import 'core/utils/responsive_helper.dart';
import 'core/utils/system_ui.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: ResponsiveHelper.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        ResponsiveHelper.configureClampedScreenUtil(context);
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: MaterialApp.router(
            title: 'Wash Up',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: MyAppTheme.lightTheme,
            darkTheme: MyAppTheme.darkTheme,
            themeMode: themeMode,
            locale: locale,
            routerConfig: appRouter,
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
