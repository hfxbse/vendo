import 'dart:async';
import 'dart:math';

import 'package:flutter_gpiod/flutter_gpiod.dart';

class CoinDispenser {
  final GpioLine control;
  final List<GpioLine> selectionPins;
  final List<double> coinValues;

  static const _controlConsumerName = "COIN_DISPENSER_CONTROL";

  CoinDispenser({
    required this.control,
    required this.selectionPins,
    required this.coinValues,
  })  : // All coin values are addressable with the given selection pins
        assert(pow(2, selectionPins.length) >= coinValues.length),
        // Control pin not also used as selection pin
        assert(!selectionPins.contains(control)),
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

  Future<void> dispense(double coin) async {
    var position = coinValues.indexOf(coin) + 1;

    assert(position > 0);
    if (position == 0) return;

    await _resetSelection();

    for (final pin in selectionPins) {
      pin.setValue(position & 1 == 1);
      position >>= 1;
    }

    await _waitForDispenser();
  }

  Future<void> _waitForDispenser() async {
    const edge = SignalEdge.rising;

    control.requestInput(
      consumer: _controlConsumerName,
      bias: Bias.disable,
      activeState: ActiveState.high,
      triggers: {edge},
    );

    await control.onEvent.where((event) => event.edge == edge).first;
    control.release();
  }

  Future<void> _resetSelection() async {
    for (final pin in selectionPins) {
      pin.setValue(false);
    }

    await Future.delayed(const Duration(milliseconds: 10));

    control.requestOutput(
      consumer: _controlConsumerName,
      initialValue: true,
      activeState: ActiveState.low,
      outputMode: OutputMode.pushPull,
    );

    await Future.delayed(const Duration(milliseconds: 10));
    control.setValue(false);

    control.release();
  }
}
