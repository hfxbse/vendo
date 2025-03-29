import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/driver/coin_selector.dart';
import 'package:vendo/driver/coin_dispenser.dart';
import 'package:vendo/driver/drink_dispenser.dart';
import 'package:vendo/payment_provider.dart';

import 'payment_provider_test.mocks.dart';

@GenerateMocks([CoinSelector, CoinDispenser, DrinkDispenser])
void main() {
  test('Payed amount should add up', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    final coins = Stream.fromIterable([0.05, 0.10, 0.20, 0.50, 1.00, 2.00]);

    when(coinSelector.coins).thenAnswer((_) => coins);

    final stream = PaymentProvider(
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ).payment(42).timeout(const Duration(milliseconds: 100));

    const epsilon = 0.001;
    expect(
      stream,
      emitsInOrder(
        [
          closeTo(0.05, epsilon),
          closeTo(0.15, epsilon),
          closeTo(0.35, epsilon),
          closeTo(0.85, epsilon),
          closeTo(1.85, epsilon),
          closeTo(3.85, epsilon),
        ],
      ),
    );
  });
}
