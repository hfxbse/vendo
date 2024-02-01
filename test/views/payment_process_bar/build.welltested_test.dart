import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/views/payment_process_bar.dart';

void main() {
  group('PaymentProcessBar', () {
    testWidgets(
      'displays correct payment progress when valid payment stream is provided',
      (WidgetTester tester) async {
        final paymentStream = Stream.fromIterable([1.0, 2.0, 3.0]);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(paymentStream, 6.0),
          ),
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 3.00 €'), findsOneWidget);

        await expectLater(
          find.byType(PaymentProcessBar),
          matchesGoldenFile('golden/payment_process_bar_valid_stream.png'),
        );
      },
    );

    testWidgets(
      'displays correct payment progress when no payment stream is provided',
      (WidgetTester tester) async {
        final paymentStream = Stream<double>.fromIterable([]);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(paymentStream, 1.0),
          ),
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 1.00 €'), findsOneWidget);

        await expectLater(
          find.byType(PaymentProcessBar),
          matchesGoldenFile('golden/payment_process_bar_no_stream.png'),
        );
      },
    );

    testWidgets(
      'displays correct payment progress when payment stream is provided in random order',
      (WidgetTester tester) async {
        final paymentStream = Stream.fromIterable([2.0, 1.0, 6.0]);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(paymentStream, 6.0),
          ),
        ));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 0.00 €'), findsOneWidget);

        await expectLater(
          find.byType(PaymentProcessBar),
          matchesGoldenFile('golden/payment_process_bar_random_order.png'),
        );
      },
    );
  });
}
