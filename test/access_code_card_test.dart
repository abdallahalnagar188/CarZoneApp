import 'package:washup/commons/models/order_model.dart';
import 'package:washup/core/enums/enums.dart';
import 'package:washup/features/bookings/presentaion/widgets/access_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

OrderModel _order(OrderStatus status) => OrderModel(
      id: 'o_test',
      number: 'CZ-1',
      code: 'AB12C',
      customerId: 'cu_test',
      vehicleId: 'veh_test',
      branchId: 'br_test',
      items: const [],
      subtotal: 100,
      discount: 0,
      total: 100,
      durationMin: 30,
      scheduledAt: DateTime(2026, 11, 1, 10),
      status: status,
      createdAt: DateTime(2026, 11, 1, 9),
    );

Future<void> _pump(WidgetTester tester, OrderStatus status) => tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(body: AccessCodeCard(order: _order(status))),
        ),
      ),
    );

void main() {
  testWidgets('a pending booking waits for the wash and shows no code', (tester) async {
    await _pump(tester, OrderStatus.pending);

    expect(find.text('book.codeWait'), findsOneWidget);
    expect(find.text('A B 1 2 C'), findsNothing);
  });

  testWidgets('a confirmed booking shows the code', (tester) async {
    await _pump(tester, OrderStatus.confirmed);

    expect(find.text('A B 1 2 C'), findsOneWidget);
    expect(find.text('book.codeWait'), findsNothing);
  });
}
