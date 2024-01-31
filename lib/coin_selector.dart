import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:welltested_annotation/welltested_annotation.dart';

@Welltested()
class CoinSelector {
  const CoinSelector({
    required this.pulsePin,
    required this.pulseBias,
    required this.pulseActiveState,
    required this.pulseEndEdge,
    required this.coinValues,
  });

  final GpioLine pulsePin;
  final Bias pulseBias;
  final ActiveState pulseActiveState;
  final SignalEdge pulseEndEdge;
  final List<double> coinValues;

  @Testcases([
    "GpioLine gets setup as input when listener starts or continues",
    "GpioLine gets released when listener pauses or cancels",
    "Returns the first coin value when receiving two pulses, in which a pulse consists out of two SignalEvents. "
        "A pulse consists out of a rising SignalEvent marking the start of the pulse, and a falling SignalEvent "
        "marking the end. Those SignalEvents are 30 milliseconds apart. The pulses end and the next pulse start are "
        "104 milliseconds apart.",
  ])
  Stream<double> coins() {
    late StreamController<double> controller;
    late StreamSubscription eventListener;

    void listenForPulses() {
      int impulses = 0;

      void addCoin() {
        if (impulses > 1 && coinValues.length * 2 >= impulses) {
          controller.add(coinValues[(impulses / 2 - 1).floor()]);
        }

        impulses = 0;
      }

      final events = pulsePin.onEvent.where(
        (event) => event.edge == pulseEndEdge,
      );

      eventListener = events.timeout(
        const Duration(milliseconds: 136),
        onTimeout: (sink) {
          addCoin();

          sink.close();
          listenForPulses();
        },
      ).listen(
        (event) {
          ++impulses;
        },
        onDone: () {
          addCoin();
        },
      );
    }

    void activate() {
      pulsePin.requestInput(
        consumer: "COIN_SELECTOR",
        bias: pulseBias,
        activeState: pulseActiveState,
        triggers: {pulseEndEdge},
      );

      listenForPulses();
    }

    void deactivate() {
      pulsePin.release();
      eventListener.cancel();
    }

    controller = StreamController(
      onListen: activate,
      onResume: activate,
      onCancel: deactivate,
      onPause: deactivate,
    );

    return controller.stream;
  }

  @override
  String toString() {
    return 'CoinSelector{#'
        'pulsePin: ${pulsePin.info.name}, '
        'pulseBias: $pulseBias, '
        'pulseActiveState: $pulseActiveState, '
        'pulseEndEdge: $pulseEndEdge'
        '}';
  }
}
