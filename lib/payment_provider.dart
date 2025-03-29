import 'dart:async';

import 'package:vendo/driver/coin_dispenser.dart';
import 'package:vendo/driver/drink_dispenser.dart';

import 'driver/coin_selector.dart';

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
