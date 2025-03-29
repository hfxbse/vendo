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

  void dispenserDemo(List<double> coinValues) async {
    for (final coin in coinValues) {
      coinDispenser.dispense(coin);
    }
  }

  Stream<double> payment(double price) {
    double payed = 0;

    return coinSelector.coins.map((coin) {
      payed += coin;
      return payed;
    });
  }
}
