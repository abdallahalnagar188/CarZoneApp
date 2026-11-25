import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// GAP-032: page controllers are GetX singletons, so a second page of the same
/// route (a push or deep link for wash/booking B while A is open) gets the
/// controller that is still showing A. Each open page registers its own route
/// argument here; the controller always shows the top-most page's argument and
/// goes back to the one below when that page closes.
mixin RouteArgumentStack on GetxController {
  final _open = <String>[];

  /// The argument (wash or order id) the controller currently shows.
  final activeArgument = ''.obs;

  /// Reload everything for [activeArgument]; called when it changes.
  void onArgumentChanged();

  /// Sets the first argument without a reload (the controller loads it itself).
  void initArgument(String? argument) => activeArgument.value = argument ?? '';

  /// A page for [argument] opened on top.
  void pushArgument(String? argument) {
    if (argument == null || argument.isEmpty) return;
    _open.add(argument);
    if (activeArgument.value == argument) return;
    activeArgument.value = argument;
    onArgumentChanged();
  }

  /// The page for [argument] closed: show the page below it again.
  void popArgument(String? argument) {
    if (argument == null) return;
    final i = _open.lastIndexOf(argument);
    if (i < 0) return;
    _open.removeAt(i);
    if (_open.isEmpty) return;
    final top = _open.last;
    if (top == activeArgument.value) return;
    activeArgument.value = top;
    onArgumentChanged();
  }
}

/// Wraps a page whose controller uses [RouteArgumentStack]: registers the
/// page's route argument while it is open, and shows [placeholder] until the
/// controller has switched to it.
class RouteArgumentScope<T extends RouteArgumentStack> extends StatefulWidget {
  final Widget child;
  final Widget placeholder;

  const RouteArgumentScope({super.key, required this.child, this.placeholder = const SizedBox.shrink()});

  @override
  State<RouteArgumentScope<T>> createState() => _RouteArgumentScopeState<T>();
}

class _RouteArgumentScopeState<T extends RouteArgumentStack> extends State<RouteArgumentScope<T>> {
  /// This page's own argument, read once when the route opens.
  final String? _argument = Get.arguments?.toString();

  @override
  void initState() {
    super.initState();
    // After the frame: switching the controller rebuilds the page below too,
    // which must not happen while this one is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<T>()) Get.find<T>().pushArgument(_argument);
    });
  }

  @override
  void dispose() {
    final argument = _argument;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<T>()) Get.find<T>().popArgument(argument);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final argument = _argument;
    if (argument == null || argument.isEmpty) return widget.child;
    return Obx(() => Get.find<T>().activeArgument.value == argument ? widget.child : widget.placeholder);
  }
}
