import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washup/commons/styles/themes/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('text has no letter spacing (dark: $dark)', (tester) async {
      late TextTheme text;
      late TextTheme primary;
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          theme: dark ? MyAppTheme.darkTheme : MyAppTheme.lightTheme,
          // The app sets no Material localizations, so text uses the
          // English-like scale whatever the language.
          home: Builder(builder: (context) {
            text = Theme.of(context).textTheme;
            primary = Theme.of(context).primaryTextTheme;
            return const SizedBox();
          }),
        ),
      ));
      for (final theme in [text, primary]) {
        for (final style in [
          theme.displayLarge, theme.headlineSmall, theme.titleMedium, theme.titleSmall,
          theme.bodyLarge, theme.bodyMedium, theme.bodySmall,
          theme.labelLarge, theme.labelMedium, theme.labelSmall,
        ]) {
          expect(style?.letterSpacing ?? 0, 0, reason: style?.debugLabel);
        }
      }
    });
  }
}
