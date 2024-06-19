import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_gpiod/flutter_gpiod.dart';

class CoinDispenser {
  final GpioLine controlPin;
  final List<GpioLine> selectionPins;
  final List<double> coinValues;

  final Queue<double> _queue = Queue();

  static const _controlConsumerName = "COIN_DISPENSER_CONTROL";

  CoinDispenser({
    required this.controlPin,
    required this.selectionPins,
    required this.coinValues,
  })  : // All coin values are addressable with the given selection pins
        assert(pow(2, selectionPins.length) >= coinValues.length),
        // Control pin not also used as selection pin
        assert(!selectionPins.contains(controlPin)),
        // No duplicate selection pins
        assert(Set.from(selectionPins).length == selectionPins.length) {
    for (final pin in selectionPins) {
      pin.requestOutput(
        consumer: "COIN_DISPENSER_SELECTION",
        initialValue: false,
        activeState: ActiveState.high,
        outputMode: OutputMode.pushPull,
      );
    }
  }

  void dispense(double coin) {
    _queue.addLast(coin);

    if (_queue.length == 1) _start().catchError((_) => _releasePins());
  }

  bool get done => _queue.isEmpty;

  Future<void> _start() async {
    while (_queue.isNotEmpty) {
      final coin = _queue.first;

      var position = coinValues.indexOf(coin) + 1;

      assert(position > 0);
      if (position == 0) return;

      await _resetSelection();

      for (final pin in selectionPins) {
        pin.setValue(position & 1 == 1);
        position >>= 1;
      }

      await _waitForDispenser();
      _queue.removeFirst();
    }
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
