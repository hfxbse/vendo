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

  Stream<int> payment(int price, {Function()? onTransactionCompletion}) {
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

      final fullyPayed = _fullyPayed(price: price, payed: payed);
      
      await Future.wait([
        _dispenseChange(fullyPayed ? payed - price : payed),
        if(fullyPayed) drinkDispenser.dispenseDrink()..then((_) {
          if(onTransactionCompletion != null) onTransactionCompletion();
        })
      ]);
    };

    return controller.stream;
  }

  Future<void> _dispenseChange(int change) async {
    final values = coinDispenser.coinValues.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));

    while (change > 0) {
      final match = values.firstWhere((coin) => change >= coin);

      coinDispenser.dispenseCoin(match);
      change -= match;
    }
  }
}
