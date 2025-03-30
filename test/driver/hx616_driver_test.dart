import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/driver/hx616_driver.dart';

import 'mock_gpio_line.dart';

void main() {
  group('GPIOs should setup up when listening', () {
    final pin = MockGpioLine();
    when(pin.onEvent).thenAnswer((realInvocation) => const Stream.empty());

    final coinSelectors = [
      HX616Driver(
        pulsePin: pin,
        pulseBias: Bias.pullUp,
        pulseActiveState: ActiveState.high,
        pulseEndEdge: SignalEdge.rising,
        coinValues: [],
      ),
      HX616Driver(
        pulsePin: pin,
        pulseBias: Bias.pullDown,
        pulseActiveState: ActiveState.low,
        pulseEndEdge: SignalEdge.falling,
        coinValues: [],
      ),
      HX616Driver(
        pulsePin: pin,
        pulseBias: Bias.disable,
        pulseActiveState: ActiveState.high,
        pulseEndEdge: SignalEdge.rising,
        coinValues: [],
      )
    ];

    group('When first listener requested', () {
      for (final coinSelector in coinSelectors) {
        test(coinSelector.toString(), () {
          coinSelector.coins.listen((_) {});

          verify(pin.requestInput(
            consumer: anyNamed('consumer'),
            activeState: coinSelector.pulseActiveState,
            bias: coinSelector.pulseBias,
            triggers: {coinSelector.pulseEndEdge},
          )).called(1);
        });
      }
    });

    group('When listener resumes', () {
      for (final coinSelector in coinSelectors) {
        test(coinSelector.toString(), () {
          final subscription = coinSelector.coins.listen((_) {});
          subscription.pause();
          subscription.resume();

          verify(pin.requestInput(
            consumer: anyNamed('consumer'),
            activeState: coinSelector.pulseActiveState,
            bias: coinSelector.pulseBias,
            triggers: {coinSelector.pulseEndEdge},
          )).called(2);
        });
      }
    });
  });

  group('GPIO should release when listening stopped', () {
    final pin = MockGpioLine();
    when(pin.onEvent).thenAnswer((_) => const Stream.empty());

    final coinSelector = HX616Driver(
      pulsePin: pin,
      pulseBias: Bias.disable,
      pulseActiveState: ActiveState.high,
      pulseEndEdge: SignalEdge.rising,
      coinValues: [],
    );

    test('When listener canceled', () {
      coinSelector.coins.listen((_) {}).cancel();
      verify(pin.release()).called(1);
    });

    test('When listener paused', () {
      coinSelector.coins.listen((_) {}).pause();
      verify(pin.release()).called(1);
    });
  });

  const pulseMilliseconds = 30;
  const pulsePauseMilliseconds = 104;
  const cycleMilliseconds = pulseMilliseconds + pulsePauseMilliseconds;
  const betweenMilliseconds = cycleMilliseconds - 1;

  List<Future<SignalEvent>> createPulses(
    int pulseCount,
    SignalEdge pulseStartEdge,
    SignalEdge pulseEndEdge, [
    int millisOffset = 0,
  ]) =>
      List.generate(
        pulseCount * 2,
        (index) {
          final pulse = (index / 2).floor();
          final cycleEnd = index % 2 == 1;

          final delayMillis = millisOffset +
              betweenMilliseconds * pulse +
              (cycleEnd ? pulseMilliseconds : 0);

          return Future.delayed(
            Duration(milliseconds: delayMillis),
            () => SignalEvent(
              cycleEnd ? pulseEndEdge : pulseStartEdge,
              delayMillis * 1000000,
              Duration(milliseconds: delayMillis),
              DateTime.fromMillisecondsSinceEpoch(delayMillis),
            ),
          );
        },
      );

  group('Coin values should be recognised', () {
    const coinValues = [5, 10, 20, 50, 100, 200];

    for (final (index, coin) in coinValues.indexed) {
      final pulseCount = (index + 1) * 2;

      test(
        "${(coin.toDouble() / 100).toStringAsFixed(2)} € with $pulseCount pulses",
        () {
          final pin = MockGpioLine();
          final coinSelector = HX616Driver(
            pulsePin: pin,
            pulseBias: Bias.disable,
            pulseActiveState: ActiveState.high,
            pulseEndEdge: SignalEdge.rising,
            coinValues: coinValues,
          );

          final pulses = Stream.fromFutures(createPulses(
            pulseCount,
            SignalEdge.falling,
            coinSelector.pulseEndEdge,
          )).asBroadcastStream();

          when(pin.onEvent).thenAnswer((_) => pulses);

          final stream = coinSelector.coins.timeout(
            Duration(milliseconds: cycleMilliseconds * (pulseCount + 1)),
          );

          expect(stream, emits(coin));
        },
      );
    }
  });

  test('Unrecognized coins should be ignored', () {
    final coinValues = [5];

    final pin = MockGpioLine();
    final HX616Driver coinSelector = HX616Driver(
      pulsePin: pin,
      pulseBias: Bias.disable,
      pulseActiveState: ActiveState.high,
      pulseEndEdge: SignalEdge.rising,
      coinValues: coinValues,
    );

    final pulseCount = coinValues.length * 2 + 2;
    final pulses = Stream.fromFutures(createPulses(
      pulseCount,
      SignalEdge.falling,
      coinSelector.pulseEndEdge,
    )).asBroadcastStream();

    when(pin.onEvent).thenAnswer((_) => pulses);

    final stream = coinSelector.coins.timeout(
      Duration(milliseconds: (pulseCount + 1) * cycleMilliseconds),
      onTimeout: (sink) => sink.close(),
    );

    expect(stream, neverEmits(coinValues.first));
  });

  test('Consecutive coins should be recognized', () {
    final coinValues = [5, 10, 20, 50, 100, 200];

    final pin = MockGpioLine();
    final HX616Driver coinSelector = HX616Driver(
      pulsePin: pin,
      pulseBias: Bias.disable,
      pulseActiveState: ActiveState.high,
      pulseEndEdge: SignalEdge.rising,
      coinValues: coinValues,
    );

    final pulses = List.generate(coinValues.length, (index) {
      return createPulses(
        (index + 1) * 2,
        SignalEdge.falling,
        coinSelector.pulseEndEdge,
      );
    });

    when(pin.onEvent).thenAnswer(
      (_) {
        late StreamController<SignalEvent> controller;

        void addPulses() {
          if (pulses.isNotEmpty) {
            controller.addStream(Stream.fromFutures(pulses.removeAt(0)));
          }
        }

        controller = StreamController(onListen: addPulses, onResume: addPulses);

        return controller.stream;
      },
    );

    final stream = coinSelector.coins.timeout(
      Duration(milliseconds: cycleMilliseconds * (coinValues.length + 2)),
    );

    expect(stream, emitsInOrder(coinValues));
  });
}
