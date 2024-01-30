import 'dart:async';

import 'coin_selector.dart';

class PaymentProvider {
  PaymentProvider(this.coinSelector);

  final CoinSelector coinSelector;

  Stream<double> payment(double price) {
    late StreamController<double> controller;
    late StreamSubscription eventListener;

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

      void addCoin() {
        if (impulses > 0) {
          final coinValue = coinMapping[(impulses / 2).floor()];
          payed += coinValue;
          controller.add(payed);
        }

        impulses = 0;
      }

      eventListener = coinSelector.events.timeout(
        const Duration(milliseconds: 136),
        onTimeout: (sink) {
          addCoin();

          sink.close();
          readCoinSelector();
        },
      ).listen((event) {
        ++impulses;
      }, onDone: () {
        addCoin();
      });
    }

    void claimCoinSelector() {
      coinSelector.activate();
      readCoinSelector();
    }

    void releaseCoinSelector() {
      coinSelector.deactivate();
      eventListener.cancel();
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
