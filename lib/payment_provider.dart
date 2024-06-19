import 'dart:async';

import 'package:vendo/driver/coin_dispenser.dart';

import 'driver/coin_selector.dart';

class PaymentProvider {
  PaymentProvider(this.coinSelector, this.coinDispenser);

  final CoinSelector coinSelector;
  final CoinDispenser coinDispenser;

  void dispenserDemo(List<double> coinValues) async {
    for (final coin in coinValues) {
      await coinDispenser.dispense(coin);
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
