# washup

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI

`.github/workflows/ci.yml` (GAP-055) runs on every pull request and on pushes to `main` / `ebrahim`:
`flutter pub get` → `flutter analyze` → `flutter test --exclude-tags live`, with the Flutter pinned in
`shorebird.yml` and `codemagic.yaml` (3.47.7; `test/qa/ci_flutter_version_test.dart` keeps the three equal).
No secrets. Tests tagged `live` (`dart_test.yaml`) call the deployed Supabase project and are left out of CI;
run them by hand with `flutter test --tags live`. Builds and releases stay in `shorebird.yml` / Codemagic.
