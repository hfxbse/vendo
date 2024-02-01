import 'build.welltested_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/views/payment_process_bar.dart';

@GenerateMocks([Stream])
void main() {
  group('PaymentProcessBar', () {
    testWidgets(
      'displays correct payment progress when valid payment stream is provided',
      (WidgetTester tester) async {
        final mockPaymentStream = MockStream<double>();
        when(mockPaymentStream.asBroadcastStream())
            .thenAnswer((_) => Stream.fromIterable([1.0, 2.0, 3.0]));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(mockPaymentStream, 6.0),
          ),
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 3.00 €'), findsOneWidget);
      },
    );

    testWidgets(
      'displays correct payment progress when no payment stream is provided',
      (WidgetTester tester) async {
        final mockPaymentStream = MockStream<double>();
        when(mockPaymentStream.asBroadcastStream())
            .thenAnswer((_) => Stream.fromIterable([]));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(mockPaymentStream, 0.0),
          ),
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 0.00 €'), findsOneWidget);
      },
    );

    testWidgets(
      'displays correct payment progress when payment stream is provided in random order',
      (WidgetTester tester) async {
        final mockPaymentStream = MockStream<double>();
        when(mockPaymentStream.asBroadcastStream())
            .thenAnswer((_) => Stream.fromIterable([2.0, 1.0, 3.0]));

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PaymentProcessBar(mockPaymentStream, 6.0),
          ),
        ));

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Offener Betrag: 0.00 €'), findsOneWidget);
      },
    );
  });
}
