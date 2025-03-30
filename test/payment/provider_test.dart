import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/payment/coin_dispenser.dart';
import 'package:vendo/payment/coin_selector.dart';
import 'package:vendo/payment/drink_dispenser.dart';
import 'package:vendo/payment/provider.dart';

import 'provider_test.mocks.dart';

class Functions {
  void callback() {}
}

@GenerateMocks([CoinSelector, CoinDispenser, DrinkDispenser, Functions])
void main() {
  test('Payed amount should add up', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    final coins = Stream.fromIterable([5, 10, 20, 50, 100, 200]);

    when(coinSelector.coins).thenAnswer((_) => coins);
    when(coinDispenser.coinValues).thenAnswer((_) => [1]);

    final stream = PaymentProvider(
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ).payment(420).timeout(const Duration(milliseconds: 100));

    expect(
      stream,
      emitsInOrder([5, 15, 35, 85, 185, 385]),
    );
  });

  test('Stops counting after price amount is reached', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    final coins = Stream.fromIterable([5, 10, 20, 50, 100, 200]);

    when(coinSelector.coins).thenAnswer((_) => coins);
    when(coinDispenser.coinValues).thenAnswer((_) => [1]);

    final stream = PaymentProvider(
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ).payment(50).timeout(const Duration(milliseconds: 100));

    expect(
      stream,
      emitsInOrder([5, 15, 35, 85]),
    );
  });

  group('Change dispense', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    when(coinDispenser.dispenseCoin(any)).thenAnswer((_) => Future.sync(() {}));

    group('Price not met', () {
      when(coinDispenser.coinValues).thenAnswer((_) => [1]);

      test(
        'Returns payed amount if payment is canceled and price not met',
        () async {
          const price = 798;
          const payed = 42;
          final coins = Stream.fromIterable([payed]);

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verify(coinDispenser.dispenseCoin(1)).called(payed);
          }
        },
      );

      test(
        'Returns nothing if payment is canceled and nothing has been payed',
        () async {
          const price = 465;
          final coins = Stream.fromIterable(List<int>.empty());

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verifyNever(coinDispenser.dispenseCoin(any));
          }
        },
      );
    });

    group('Price met', () {
      when(coinDispenser.coinValues).thenAnswer((_) => [1]);

      test(
        'Returns correct change amount if price is exceeded',
        () async {
          const price = 50;
          const change = 85;
          final coins = Stream.fromIterable([price + change]);

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verify(coinDispenser.dispenseCoin(1)).called(change);
          }
        },
      );

      test(
        'Returns nothing if price is exactly matched',
        () async {
          const price = 34;
          final coins = Stream.fromIterable([price]);

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verifyNever(coinDispenser.dispenseCoin(any));
          }
        },
      );
    });
  });

  group('Drink dispense', () {
    late MockCoinDispenser coinDispenser;
    late MockDrinkDispenser drinkDispenser;
    late MockFunctions mockCallback;

    setUp(() {
      coinDispenser = MockCoinDispenser();
      drinkDispenser = MockDrinkDispenser();
      mockCallback = MockFunctions();

      when(coinDispenser.dispenseCoin(any)).thenAnswer((_) => Future.sync(() {}));
      when(coinDispenser.coinValues).thenAnswer((_) => [1]);
    });

    group("Price fully paid", () {
      const price = 50;
      final coins = Stream.fromIterable([price]);

      final coinSelector = MockCoinSelector();
      when(coinSelector.coins).thenAnswer((_) => coins);

      stream() => PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          )
              .payment(price, onTransactionCompletion: mockCallback.callback)
              .timeout(const Duration(milliseconds: 100));

      test('Does call the transaction completion callback', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verify(mockCallback.callback()).called(1);
        }
      });

      test('Does start the drink dispensation', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verify(drinkDispenser.dispenseDrink()).called(1);
        }
      });
    });

    group("Transaction canceled", () {
      const price = 34;
      final coins = Stream.fromIterable([price - 1]);

      final coinSelector = MockCoinSelector();
      when(coinSelector.coins).thenAnswer((_) => coins);

      stream() => PaymentProvider(
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          )
              .payment(price, onTransactionCompletion: mockCallback.callback)
              .timeout(const Duration(milliseconds: 100));

      test('Does not call the transaction completion callback', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verifyNever(mockCallback.callback());
        }
      });

      test('Does not start the drink dispensation', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verifyNever(drinkDispenser.dispenseDrink());
        }
      });
    });
  });
}
