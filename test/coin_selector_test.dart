import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';

import 'coin_selector_test.mocks.dart';

@GenerateMocks([GpioLine])
void main() {
  group('GPIO pin should get set up when listening on coin selector', () {
    test('When listening on coin selector', () {
      final mockGpioLine = MockGpioLine();
      final coinSelector = CoinSelector(
        pulsePin: mockGpioLine,
        pulseBias: Bias.pullUp,
        coinValues: const [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
        pulseEndEdge: SignalEdge.falling,
        pulseActiveState: ActiveState.low,
      );

      when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

      coinSelector.coins.listen((_) {});

      verify(mockGpioLine.requestInput(
        consumer: anyNamed('consumer'),
        bias: Bias.pullUp,
        activeState: ActiveState.low,
        triggers: {
          SignalEdge.falling,
        },
      )).called(1);
    });

    test('When resuming listening', () {
      final mockGpioLine = MockGpioLine();
      final coinSelector = CoinSelector(
        pulsePin: mockGpioLine,
        pulseBias: Bias.pullUp,
        coinValues: const [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
        pulseEndEdge: SignalEdge.falling,
        pulseActiveState: ActiveState.low,
      );

      when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

      final subscription = coinSelector.coins.listen((_) {});
      subscription.pause();
      subscription.resume();

      verify(mockGpioLine.requestInput(
        consumer: anyNamed('consumer'),
        bias: Bias.pullUp,
        activeState: ActiveState.low,
        triggers: {
          SignalEdge.falling,
        },
      )).called(2);
    });
  });

  group('GPIO pin should get released stop listening on coin selector', () {
    test('When cancelling subscription', () {
      final mockGpioLine = MockGpioLine();
      final coinSelector = CoinSelector(
        pulsePin: mockGpioLine,
        pulseBias: Bias.pullUp,
        coinValues: const [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
        pulseEndEdge: SignalEdge.falling,
        pulseActiveState: ActiveState.low,
      );

      when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

      final subscription = coinSelector.coins.listen((_) {});
      subscription.cancel();

      verify(mockGpioLine.release()).called(1);
    });

    test('When coin selector ist paused', () {
      final mockGpioLine = MockGpioLine();
      final coinSelector = CoinSelector(
        pulsePin: mockGpioLine,
        pulseBias: Bias.pullUp,
        coinValues: const [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
        pulseEndEdge: SignalEdge.falling,
        pulseActiveState: ActiveState.low,
      );

      when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

      final subscription = coinSelector.coins.listen((_) {});
      subscription.pause();

      verify(mockGpioLine.release()).called(1);
    });
  });

  // Coin values should be emitted when coin is inserted. A coin is inserted when the GPIO pin receives two pulses.
  // A pulse is a falling edge followed by a rising edge separated by 30ms. Between the two pulses there is a pause of
  // 100ms. The coin value is emitted when the second pulse is received. The number of pulses matches the
  // (position of the coin value in the coinValues list) + 1 * 2.
  group('Coin values should be detected', () {
    const coinValues = [0.05, 0.10, 0.20, 0.50, 1.00, 2.00];

    for (var (position, coinValue) in coinValues.indexed) {
      final mockGpioLine = MockGpioLine();

      test('When coin value is $coinValue', () {
        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullUp,
          coinValues: coinValues,
          pulseEndEdge: SignalEdge.rising,
          pulseActiveState: ActiveState.low,
        );

        when(mockGpioLine.onEvent).thenAnswer(
          (_) => Stream.fromFutures(
            List.generate(
              4 * (position + 1),
              (index) {
                final timeOffset = index * 100 + (index % 2 == 0 ? 0 : 30);

                final event = SignalEvent(
                      index % 2 == 0 ? SignalEdge.falling : SignalEdge.rising,
                      timeOffset * 1000000,
                      // time offset as duration
                      Duration(milliseconds: timeOffset),
                      // time offset as timestamp
                      DateTime.now().add(Duration(milliseconds: timeOffset)),
                    );

                return Future.delayed(
                  Duration(microseconds: timeOffset),
                  () => event,
                );
              },
            ),
          ),
        );

        expect(
          coinSelector.coins.timeout(const Duration(seconds: 3)),
          emits(coinValue),
        );
      });
    }
  });

  // Two consecutive coins should be detected
  test('Two consecutive coins should be detected and emitted separately', () {
    final mockGpioLine = MockGpioLine();

    final coinSelector = CoinSelector(
      pulsePin: mockGpioLine,
      pulseBias: Bias.pullUp,
      coinValues: const [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
      pulseEndEdge: SignalEdge.falling,
      pulseActiveState: ActiveState.low,
    );

    final List<List<Future<SignalEvent>>> coinPulses = [
      [0, 30, 130, 160].indexed.map(
        (element) {
          final timeOffset = element.$2;

          final event = SignalEvent(
            element.$1 % 2 == 0 ? SignalEdge.falling : SignalEdge.rising,
            timeOffset * 1000000,
            // time offset as duration
            Duration(milliseconds: timeOffset),
            // time offset as timestamp
            DateTime.now().add(Duration(milliseconds: timeOffset)),
          );

          return Future.delayed(
            Duration(milliseconds: timeOffset),
            () => event,
          );
        },
      ).toList(),
      [0, 30, 130, 160, 260, 290, 390, 520].indexed.map(
        (element) {
          final timeOffset = element.$2;

          final event = SignalEvent(
            element.$1 % 2 == 0 ? SignalEdge.falling : SignalEdge.rising,
            timeOffset * 1000000,
            // time offset as duration
            Duration(milliseconds: timeOffset),
            // time offset as timestamp
            DateTime.now().add(Duration(milliseconds: timeOffset)),
          );

          return Future.delayed(
            Duration(milliseconds: timeOffset),
            () => event,
          );
        },
      ).toList(),
    ];

    when(mockGpioLine.onEvent).thenAnswer((_) {
      late StreamController<SignalEvent> streamController;

      void popPulses() {
        if (coinPulses.isEmpty) {
          return;
        }

        final pulses = coinPulses.removeAt(0);
        streamController.addStream(
          Stream.fromFutures(pulses),
        );
      }

      streamController = StreamController(
        onListen: popPulses,
        onResume: popPulses,
      );

      return streamController.stream;
    });

    expect(
      coinSelector.coins.timeout(const Duration(seconds: 3)),
      emitsInOrder(
        [
          0.05,
          0.10,
        ],
      ),
    );
  });
}
