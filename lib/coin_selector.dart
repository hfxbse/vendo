import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';

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

  Stream<double> get coins {
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
