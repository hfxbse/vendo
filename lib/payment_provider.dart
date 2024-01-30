import 'dart:async';

import 'coin_selector.dart';

class PaymentProvider {
  PaymentProvider(this.coinSelector);

  final CoinSelector coinSelector;

  Stream<double> payment(double price) {
    double payed = 0;

    return coinSelector.coins.map((coin) {
      payed += coin;
      return payed;
    });
  }
}
