// ignore_for_file: avoid_print

import 'dart:async';

import 'package:vendo/payment/coin_dispenser.dart';
import 'package:vendo/payment/coin_selector.dart';
import 'package:vendo/payment/drink_dispenser.dart';

class DevelopmentDriver implements CoinDispenser, CoinSelector, DrinkDispenser {
  final _coinStreamController = StreamController<int>();
  late final _broadcast = _coinStreamController.stream.asBroadcastStream();

  @override
  final List<int> coinValues;

  DevelopmentDriver(this.coinValues);

  void dispenseCoinSlot(int slotIndex) {
    assert(slotIndex >= 0 && slotIndex < coinValues.length);
    final coin = coinValues[slotIndex];

    print('[COIN SELECTOR] Adding a ${inEuro(coin)} € coin');
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
  Stream<int> get coins => _broadcast;

  @override
  Future<void> dispense(int coin) async {
    final position = coinValues.indexOf(coin);

    print(
      '[COIN DISPENSER] Dispensing a ${inEuro(coin)} € coin at $position',
    );
  }

  String inEuro(int coinValue) {
    return (coinValue.toDouble() / 100).toStringAsFixed(2);
  }
}
