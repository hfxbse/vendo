import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:vendo/payment_provider.dart';

import 'payment_provider_test.mocks.dart';

@GenerateMocks([CoinSelector])
void main() {
  group('Coin selector activation management', () {
    test('Should activate the coin selector when listening', () {
      final coinSelector = MockCoinSelector();
      when(coinSelector.events).thenAnswer((_) => const Stream.empty());

      PaymentProvider(coinSelector).payment(0.6).listen((_) {});
      verify(coinSelector.activate()).called(1);
    });

    test('Should activate the coin selector when resumed', () {
      final coinSelector = MockCoinSelector();
      when(coinSelector.events).thenAnswer((_) => const Stream.empty());

      final subscription = PaymentProvider(
        coinSelector,
      ).payment(0.6).listen((_) {});

      subscription.pause();
      subscription.resume();

      verify(coinSelector.activate()).called(2);
    });

    test('Should deactivate the coin selector when finished', () {
      final coinSelector = MockCoinSelector();
      when(coinSelector.events).thenAnswer((_) => const Stream.empty());

      PaymentProvider(coinSelector).payment(0.6).listen((_) {}).cancel();

      verify(coinSelector.deactivate()).called(1);
    });

    test('Should deactivate the coin selector when paused', () {
      final coinSelector = MockCoinSelector();
      when(coinSelector.events).thenAnswer((_) => const Stream.empty());

      PaymentProvider(coinSelector).payment(0.6).listen((_) {}).pause();

      verify(coinSelector.deactivate()).called(1);
    });
  });

  const pulseMilliseconds = 30;
  const pulsePauseMilliseconds = 104;
  const cycleMilliseconds = pulseMilliseconds + pulsePauseMilliseconds;
  const betweenMilliseconds = cycleMilliseconds - 2;

  List<Future<SignalEvent>> createPulses(int pulseCount,
      [int millisOffset = 0]) {
    return List.generate(
      pulseCount,
      (index) {
        final delayMillis = millisOffset + betweenMilliseconds * index;

        return Future.delayed(
          Duration(milliseconds: delayMillis),
          () => SignalEvent(
            SignalEdge.falling,
            delayMillis * 1000000,
            Duration(milliseconds: delayMillis),
            DateTime.fromMillisecondsSinceEpoch(delayMillis),
          ),
        );
      },
    );
  }

  group('Should recognize coins value', () {
    for (var coin in [
      {"pulseCount": 2, "value": 0.05},
      {"pulseCount": 4, "value": 0.1},
      {"pulseCount": 6, "value": 0.2},
      {"pulseCount": 8, "value": 0.5},
      {"pulseCount": 10, "value": 1.0},
      {"pulseCount": 12, "value": 2.0},
    ]) {
      final pulseCount = coin["pulseCount"]! as int;

      final coinSelector = MockCoinSelector();
      when(coinSelector.events).thenAnswer(
        (_) => Stream.fromFutures(createPulses(pulseCount)),
      );

      final paymentProvider = PaymentProvider(coinSelector);

      final coinValue = coin['value']!;

      test("${coinValue.toStringAsFixed(2)} € with $pulseCount pulses", () {
        final stream = paymentProvider.payment(0.6).timeout(
              Duration(milliseconds: cycleMilliseconds * (pulseCount + 2)),
            );

        expect(stream, emits(coinValue));
      });
    }
  });

  test('Payed amount should add up', () {
    final coinSelector = MockCoinSelector();

    final impulses = List.of([
      createPulses(2),
      createPulses(4),
      createPulses(6),
      createPulses(8),
      createPulses(10),
      createPulses(12),
    ], growable: true);

    when(coinSelector.events).thenAnswer(
      (_) {
        late StreamController<SignalEvent> controller;

        void addPulses() {
          if (impulses.isNotEmpty) {
            controller.addStream(Stream.fromFutures(impulses.removeAt(0)));
          }
        }

        controller = StreamController(onListen: addPulses, onResume: addPulses);

        return controller.stream;
      },
    );

    final stream = PaymentProvider(coinSelector)
        .payment(42)
        .timeout(const Duration(milliseconds: cycleMilliseconds * 45));

    const epsilon = 0.001;
    expect(
      stream,
      emitsInOrder(
        [
          closeTo(0.05, epsilon),
          closeTo(0.15, epsilon),
          closeTo(0.35, epsilon),
          closeTo(0.85, epsilon),
          closeTo(1.85, epsilon),
          closeTo(3.85, epsilon),
        ],
      ),
    );
  });
}
