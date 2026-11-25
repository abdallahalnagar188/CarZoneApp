// GAP-032: one GetX controller serving several open pages of the same route
// always shows the top page's wash/booking and returns to the one below.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup/core/helpers/route_argument_stack.dart';

class _Controller extends GetxController with RouteArgumentStack {
  final loads = <String>[];

  @override
  void onArgumentChanged() => loads.add(activeArgument.value);
}

void main() {
  test('opening B over A switches to B; closing B goes back to A', () {
    final c = _Controller()..initArgument('A');
    c.pushArgument('A'); // page A registers itself: no reload
    expect(c.loads, isEmpty);

    c.pushArgument('B');
    expect(c.activeArgument.value, 'B');
    expect(c.loads, ['B']);

    c.popArgument('B');
    expect(c.activeArgument.value, 'A');
    expect(c.loads, ['B', 'A']);
  });

  test('the same wash opened twice needs no reload, and closing one keeps it', () {
    final c = _Controller()..initArgument('A');
    c
      ..pushArgument('A')
      ..pushArgument('A');
    c.popArgument('A');
    expect(c.activeArgument.value, 'A');
    expect(c.loads, isEmpty);
  });

  test('closing a page below the top changes nothing on screen', () {
    final c = _Controller()..initArgument('A');
    c
      ..pushArgument('A')
      ..pushArgument('B')
      ..pushArgument('C');
    c.popArgument('B');
    expect(c.activeArgument.value, 'C');
    c.popArgument('C');
    expect(c.activeArgument.value, 'A');
  });

  test('empty or missing arguments are ignored', () {
    final c = _Controller()..initArgument(null);
    c
      ..pushArgument(null)
      ..pushArgument('');
    expect(c.activeArgument.value, '');
    expect(c.loads, isEmpty);
  });
}
