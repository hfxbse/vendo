import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';

class PaymentProvider {
  Stream<double> payment(double price) {
    late StreamController<double> controller;
    late StreamSubscription eventListener;

    final pulsePin = FlutterGpiod.instance.chips[0].lines[26];
    double payed = 0;

    void readCoinSelector() {
      const List<double> coinMapping = [
        0.0,
        0.05,
        0.10,
        0.20,
        0.50,
        1.00,
        2.00
      ];

      int impulses = 0;

      eventListener = pulsePin.onEvent
          .where((event) => event.edge == SignalEdge.rising)
          .timeout(
        const Duration(milliseconds: 136),
        onTimeout: (sink) {
          if (impulses > 0) {
            final coinValue = coinMapping[(impulses / 2).floor()];
            controller.add(payed += coinValue);
          }

          sink.close();
          readCoinSelector();
        },
      ).listen((event) {
        ++impulses;
      });
    }

    void claimCoinSelector() {
      pulsePin.requestInput(
        consumer: "COIN",
        triggers: {SignalEdge.falling},
        bias: Bias.pullUp,
      );

      readCoinSelector();
    }

    void releaseCoinSelector() {
      eventListener.cancel();
      pulsePin.release();
    }

    controller = StreamController(
      onCancel: releaseCoinSelector,
      onPause: releaseCoinSelector,
      onResume: claimCoinSelector,
      onListen: claimCoinSelector,
    );

    return controller.stream;
  }
}
