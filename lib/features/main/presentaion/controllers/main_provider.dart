import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavNotifier extends StateNotifier<int> {
  MainNavNotifier() : super(0);

  void changeTab(int index) => state = index;
}

final mainNavIndexProvider = StateNotifierProvider<MainNavNotifier, int>((ref) {
  return MainNavNotifier();
});

