import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:vendo/payment/coin_dispenser.dart';

class CoinDispenserDriver implements CoinDispenser {
  final GpioLine controlPin;
  final List<GpioLine> selectionPins;

  @override
  final List<int> coinValues;

  Future<void>? _previousDispensation;

  static const _controlConsumerName = "COIN_DISPENSER_CONTROL";

  CoinDispenserDriver({
    required this.controlPin,
    required this.selectionPins,
    required this.coinValues,
  })  : assert(pow(2, selectionPins.length) > coinValues.length),
        // Control pin not also used as selection pin
        assert(!selectionPins.contains(controlPin)),
        // No duplicates
        assert(Set.from(coinValues).length == coinValues.length),
        assert(Set.from(selectionPins).length == selectionPins.length);

  @override
  Future<void> dispenseCoin(int coin) {
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

  void _pickSlot(int position) {
    for (final pin in selectionPins) {
      pin.setValue(position & 1 == 1);
      position >>= 1;
    }
  }

  Future<void> _onClockEdge(SignalEdge edge,
      {Duration debounceDuration = const Duration(milliseconds: 10),
      Future<void> Function()? onTimeout,
      void Function()? onOtherEdge}) async {
    while (true) {
      try {
        matcher(SignalEvent event) {
          if (kDebugMode) print("${event.edge}: ${event.timestampNanos}");

          if (event.edge != edge && onOtherEdge != null) onOtherEdge();
          return event.edge == edge;
        }

        await controlPin.onEvent
            .timeout(debounceDuration, onTimeout: (sink) => sink.close())
            .lastWhere(matcher);

        break;
      } on StateError {
        if (onTimeout != null) await onTimeout();
      }
    }
  }

  Future<void> _start(int coin) async {
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

    final position = coinValues.indexOf(coin) + 1;
    assert(position > 0 && position <= coinValues.length);
    if (kDebugMode) print("Dispense $coin cent at position $position");

    configureControlPin() {
      controlPin.requestInput(
        consumer: _controlConsumerName,
        bias: Bias.disable,
        activeState: ActiveState.high,
        triggers: SignalEdge.values.toSet(),
      );
    }

    while (true) {
      try {
        await _resetSelection();
        configureControlPin();
        _pickSlot(position);

        await _onClockEdge(
          SignalEdge.falling,
          debounceDuration: const Duration(milliseconds: 20),
          onOtherEdge: () {
            if (kDebugMode) print("Resetting selection");
            for (final pin in selectionPins) {
              pin.setValue(false);
            }
          },
          onTimeout: () async {
            if (kDebugMode) print("Waiting for falling event due to dispense");
          },
        ).timeout(const Duration(seconds: 5));

        break;
      } on TimeoutException {
        if (kDebugMode) {
          print("Dispenser seems to turned off unexpectedly. Retrying…");
        }

        controlPin.release();
      }
    }

    await _onClockEdge(
      SignalEdge.rising,
      debounceDuration: const Duration(milliseconds: 300),
      onTimeout: () async {
        if (kDebugMode) print("No rising event received after dispense");
        controlPin.release();
        await _resetSelection();
        configureControlPin();
        _pickSlot(position);
      },
    );

    _releasePins();
  }

  void _releasePins() {
    for (final pin in [...selectionPins, controlPin]) {
      if (pin.requested) pin.release();
    }
  }

  Future<void> _resetSelection() async {
    for (final pin in selectionPins) {
      pin.setValue(false);
    }

    await Future.delayed(const Duration(milliseconds: 50));

    assert(!controlPin.requested);
    controlPin.requestOutput(
      consumer: _controlConsumerName,
      initialValue: true,
      activeState: ActiveState.low,
      outputMode: OutputMode.openDrain,
      bias: Bias.pullUp,
    );

    await Future.delayed(const Duration(milliseconds: 10));
    controlPin.setValue(false);

    controlPin.release();
  }
}
