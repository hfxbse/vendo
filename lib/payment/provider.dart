import 'dart:async';

import 'coin_dispenser.dart';
import 'coin_selector.dart';
import 'drink_dispenser.dart';

class PaymentProvider {
  PaymentProvider({
    required this.coinSelector,
    required this.coinDispenser,
    required this.drinkDispenser,
  });

  final CoinSelector coinSelector;
  final CoinDispenser coinDispenser;
  final DrinkDispenser drinkDispenser;

  Future<void> _completeTransaction(int change) {
    return Future.wait([_dispenseChange(change)]);
  }

  Stream<int> payment(int price) {
    int payed = 0;

    final payedStream = coinSelector.coins
        .takeWhile((coin) => payed < price)
        .map((coin) => payed += coin)
        .asBroadcastStream();

    payedStream
        .firstWhere(
          (payed) => payed >= (price),
          orElse: () => payed,
        )
        .then(
          (payed) => price <= payed
              ? _completeTransaction(payed - price)
              : _dispenseChange(payed),
        );

    return payedStream;
  }

  Future<void> _dispenseChange(int change) async {
    final values = coinDispenser.coinValues.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));

    while (change > 0) {
      final match = values.firstWhere((coin) => change >= coin);

      coinDispenser.dispense(match);
      change -= match;
    }
  }
}
