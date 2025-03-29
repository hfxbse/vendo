import 'dart:async';
import 'dart:math';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:vendo/payment/coin_dispenser.dart';

class CoinDispenserDriver implements CoinDispenser {
  final GpioLine controlPin;
  final List<GpioLine> selectionPins;
  final List<double> coinValues;

  Future<void>? _previousDispensation;

  static const _controlConsumerName = "COIN_DISPENSER_CONTROL";

  CoinDispenserDriver({
    required this.controlPin,
    required this.selectionPins,
    required this.coinValues,
  })  : // All coin values are addressable with the given selection pins
        assert(pow(2, selectionPins.length) > coinValues.length),
        // Control pin not also used as selection pin
        assert(!selectionPins.contains(controlPin)),
        // No duplicates
        assert(Set.from(coinValues).length == coinValues.length),
        assert(Set.from(selectionPins).length == selectionPins.length);

  @override
  Future<void> dispense(double coin) {
    void errorHandler(error) {
      _releasePins();
      throw error;
    }

    if (_previousDispensation != null) {
      _previousDispensation = _previousDispensation!.then(
        (_) => _start(coin).catchError(errorHandler),
      );
    } else {
      _previousDispensation = _start(coin).catchError(errorHandler);
    }

    return _previousDispensation!;
  }

  Future<void> _start(double coin) async {
    for (final pin in selectionPins) {
      if (!pin.requested) {
        pin.requestOutput(
          consumer: "COIN_DISPENSER_SELECTION",
          initialValue: false,
          activeState: ActiveState.high,
          outputMode: OutputMode.pushPull,
        );
      }
    }

    var position = coinValues.indexOf(coin) + 1;

    assert(position > 0);
    if (position == 0) return;

    await _resetSelection();

    for (final pin in selectionPins) {
      pin.setValue(position & 1 == 1);
      position >>= 1;
    }

    await _waitForDispenser();
    _releasePins();
  }

  void _releasePins() {
    for (final pin in [...selectionPins, controlPin]) {
      if (pin.requested) pin.release();
    }
  }

  Future<void> _waitForDispenser() async {
    const edge = SignalEdge.rising;

    controlPin.requestInput(
      consumer: _controlConsumerName,
      bias: Bias.disable,
      activeState: ActiveState.high,
      triggers: {edge},
    );

    await controlPin.onEvent.where((event) => event.edge == edge).first;
    controlPin.release();
  }

  Future<void> _resetSelection() async {
    for (final pin in selectionPins) {
      pin.setValue(false);
    }

    await Future.delayed(const Duration(milliseconds: 10));

    controlPin.requestOutput(
      consumer: _controlConsumerName,
      initialValue: true,
      activeState: ActiveState.low,
      outputMode: OutputMode.pushPull,
    );

    await Future.delayed(const Duration(milliseconds: 10));
    controlPin.setValue(false);

    controlPin.release();
  }
}
