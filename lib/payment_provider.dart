import 'dart:async';

import 'package:welltested_annotation/welltested_annotation.dart';

import 'coin_selector.dart';

@Welltested()
class PaymentProvider {
  PaymentProvider(this.coinSelector);

  final CoinSelector coinSelector;

  Stream<double> payment(double price) {
    double payed = 0;

    return coinSelector.coins().map((coin) {
      payed += coin;
      return payed;
    });
  }
}
