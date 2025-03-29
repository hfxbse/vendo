// ignore_for_file: avoid_print

import 'dart:async';

import 'package:vendo/payment/coin_dispenser.dart';
import 'package:vendo/payment/coin_selector.dart';
import 'package:vendo/payment/drink_dispenser.dart';

class DevelopmentDriver implements CoinDispenser, CoinSelector, DrinkDispenser {
  final _coinStreamController = StreamController<double>();
  late final _broadcast = _coinStreamController.stream.asBroadcastStream();
  final List<double> coinValues;

  DevelopmentDriver(this.coinValues);

  void dispenseCoinSlot(int slotIndex) {
    assert(slotIndex >= 0 && slotIndex < coinValues.length);
    final coin = coinValues[slotIndex];

    print('[COIN SELECTOR] Adding a ${coin.toStringAsFixed(2)} € coin');
    _coinStreamController.add(coin);
  }

  @override
  Future<void> close() async {
    print('[DRINK DISPENSER] Closing');
  }

  @override
  Future<void> open() async {
    print('[DRINK DISPENSER] Opening');
  }

  @override
  Stream<double> get coins => _broadcast;

  @override
  Future<void> dispense(double coin) async {
    print('[COIN DISPENSER] Dispensing a ${coin.toStringAsFixed(2)} € coin');
  }
}
