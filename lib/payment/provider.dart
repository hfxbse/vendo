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

  bool _fullyPayed({required int price, required int payed}) => payed >= price;

  Stream<int> payment(int price) {
    int payed = 0;

    final controller = StreamController<int>();

    late final StreamSubscription subscription;

    subscription = coinSelector.coins.listen((coin) {
      if (controller.isClosed) {
        subscription.cancel();
        return;
      }

      payed += coin;
      controller.add(payed);

      if (_fullyPayed(price: price, payed: payed)) controller.close();
    });

    controller.onCancel = () async {
      await subscription.cancel();
      return _dispenseChange(
        _fullyPayed(price: price, payed: payed) ? payed - price : payed,
      );
    };

    return controller.stream;
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
