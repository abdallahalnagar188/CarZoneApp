// GAP-056 / GAP-057: release configuration that only fails on CI or in the store.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<int> _version(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();

bool _atLeast(String v, String min) {
  final a = _version(v);
  final b = _version(min);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return true;
}

void main() {
  final codemagic = File('codemagic.yaml').readAsStringSync();
  final shorebird = File('.github/workflows/shorebird.yml').readAsStringSync();
  final lock = File('pubspec.lock').readAsStringSync();

  final codemagicFlutter = RegExp(r'^\s+flutter:\s*([0-9.]+)', multiLine: true).firstMatch(codemagic)?.group(1);
  final shorebirdFlutter = RegExp(r"FLUTTER_VERSION:\s*'([0-9.]+)'").firstMatch(shorebird)?.group(1);
  final lockMin = RegExp(r'flutter:\s*">=([0-9.]+)"').firstMatch(lock)?.group(1);

  test('Codemagic and the Shorebird workflow build with the same Flutter', () {
    expect(codemagicFlutter, isNotNull);
    expect(shorebirdFlutter, isNotNull);
    expect(codemagicFlutter, shorebirdFlutter);
  });

  test('the pinned Flutter satisfies pubspec.lock', () {
    expect(lockMin, isNotNull);
    expect(_atLeast(codemagicFlutter!, lockMin!), isTrue, reason: 'Codemagic $codemagicFlutter < lockfile $lockMin');
  });

  test('Android release builds never fall back to the debug key', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('throw GradleException('));
    expect(gradle, contains('ALLOW_DEBUG_SIGNED_RELEASE'));
    expect(shorebird, contains('android/key.properties'));
  });
}
