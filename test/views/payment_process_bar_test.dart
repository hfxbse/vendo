import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/views/payment_process_bar.dart';

void main() {
  group("Payment process should render correctly", () {
    for (var percentage in const [0, 20, 66, 99]) {
      testWidgets("When payed $percentage %", (tester) async {
        const price = 1600;
        final payed = (price * (percentage / 100)).toInt();

        final payments = Stream.fromIterable([payed]);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaymentProcessBar(
                payment: payments,
                price: price,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byType(PaymentProcessBar),
          matchesGoldenFile(
            "goldens/payment_process_bar_$percentage.png",
          ),
        );

        final needsToBePayed = (price - payed).toDouble() / 100;

        expect(
          find.bySemanticsLabel(
            RegExp(
              ".*(^| )${needsToBePayed.toStringAsFixed(2)}(\$| ).*",
            ),
          ),
          findsOne,
        );
      });
    }
  });
}
