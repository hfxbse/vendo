import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:vendo/payment_provider.dart';

import 'payment_provider_test.mocks.dart';

@GenerateMocks([CoinSelector])
void main() {
  // test payment provider
  test('When paying with coins', () async {
    final mockCoinSelector = MockCoinSelector();
    final paymentProvider = PaymentProvider(
      mockCoinSelector,
    );

    when(mockCoinSelector.coins).thenAnswer(
      (_) => Stream.fromIterable(
        const [
          0.05,
          0.10,
          0.20,
          0.50,
          1.00,
          2.00,
        ],
      ),
    );

    final payments = paymentProvider.payment(1.00);

    // extract delta into a constant
    const delta = 0.001;
    expect(
        payments,
        emitsInOrder([
          closeTo(0.05, delta),
          closeTo(0.15, delta),
          closeTo(0.35, delta),
          closeTo(0.85, delta),
          closeTo(1.85, delta),
          closeTo(3.85, delta),
        ]));
  });
}
