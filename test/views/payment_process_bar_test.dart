import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/views/payment_process_bar.dart';

void main() {
  testWidgets("PaymentProcessBar should render correctly", (tester) async {
    final paymentStream = Stream.fromFutures(
      List.generate(
        3,
        (index) => Future.delayed(
          const Duration(seconds: 1),
          () => index.toDouble(),
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentProcessBar(
            paymentStream,
            // price
            100,
          ),
        ),
      ),
    );

    expect(find.byType(PaymentProcessBar), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));

    // golden image testing
    await expectLater(
      find.byType(PaymentProcessBar),
      matchesGoldenFile('goldens/payment_process_bar.png'),
    );
  });
}
