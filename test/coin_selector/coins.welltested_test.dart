import 'coins.welltested_test.mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';

import 'toString.welltested_test.dart';

import 'toString.welltested_test.mocks.dart';

@GenerateMocks([GpioLine, LineEvent])
void main() {
  group('CoinSelector', () {
    test(
      'GpioLine gets setup as input when listener starts or continues',
      () async {
        final mockGpioLine = MockGpioLine();
        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        final stream = coinSelector.coins();
        await stream.listen(null).pause();
        await stream.listen(null).resume();

        verify(mockGpioLine.requestInput(
          consumer: "COIN_SELECTOR",
          bias: Bias.pullDown,
          activeState: ActiveState.low,
          triggers: {SignalEdge.rising},
        )).called(2);
      },
    );

    test(
      'GpioLine gets released when listener pauses or cancels',
      () async {
        final mockGpioLine = MockGpioLine();
        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        final stream = coinSelector.coins();
        final subscription = stream.listen(null);
        await subscription.pause();
        await subscription.cancel();

        verify(mockGpioLine.release()).called(2);
      },
    );

    test(
      'Returns the first coin value when receiving two pulses',
      () async {
        final mockGpioLine = MockGpioLine();
        final mockLineEvent = MockLineEvent();
        when(mockGpioLine.onEvent)
            .thenAnswer((_) => Stream.value(mockLineEvent));
        when(mockLineEvent.edge).thenReturn(SignalEdge.rising);

        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        final stream = coinSelector.coins();
        final emittedValues = await stream.take(1).toList();

        expect(emittedValues, [1.0]);
      },
    );
  });
}
