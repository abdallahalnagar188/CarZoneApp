// Guards the iOS settings that deep links and Google Sign-In depend on.
// A wrong value here does not fail the build; it fails on the phone.
import 'dart:io';

import 'package:carzone/core/constance/supabase_constants.dart';
import 'package:flutter_test/flutter_test.dart';

String _plist() => File('ios/Runner/Info.plist').readAsStringSync();

/// Value element that follows `<key>name</key>` (whitespace-insensitive).
String? _valueAfterKey(String plist, String key) {
  final m = RegExp('<key>$key</key>\\s*(<[^>]+>(?:[^<]*</[^>]+>)?)').firstMatch(plist);
  return m?.group(1);
}

void main() {
  test('Flutter built-in deep linking is off (app_links handles links)', () {
    // When on, Flutter also pushes carzone://wash?id=… as a route name,
    // which GetX does not know, on top of what DeepLinkService opens.
    expect(_valueAfterKey(_plist(), 'FlutterDeepLinkingEnabled'), '<false/>');
  });

  test('carzone:// URL scheme is registered', () {
    expect(_plist(), contains('<string>carzone</string>'));
  });

  test('iOS Google client ID has its reversed URL scheme in Info.plist', () {
    const id = SupabaseConstants.googleIosClientId;
    if (id.isEmpty) {
      // Browser sign-in is used on iOS until an iOS client ID exists.
      return;
    }
    final prefix = id.replaceAll('.apps.googleusercontent.com', '');
    expect(_plist(), contains('<string>com.googleusercontent.apps.$prefix</string>'),
        reason: 'Google Sign-In raises a native exception and the app crashes without this URL scheme');
  });

  test('the Android client ID is never used as the iOS client ID', () {
    expect(SupabaseConstants.googleIosClientId, isNot(SupabaseConstants.googleAndroidClientId));
  });
}
