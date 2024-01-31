import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';

import 'coins.welltested_test.mocks.dart';

@GenerateMocks([GpioLine, SignalEvent])
void main() {
  group('CoinSelector', () {
    test(
      'GpioLine gets setup as input when listener starts or continues',
      () async {
        final mockGpioLine = MockGpioLine();
        when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        final stream = coinSelector.coins();

        final subscription = stream.listen(null);
        subscription.pause();
        subscription.resume();

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
        when(mockGpioLine.onEvent).thenAnswer((_) => const Stream.empty());

        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        final stream = coinSelector.coins();
        final subscription = stream.listen(null);
        subscription.pause();
        subscription.cancel();

        verify(mockGpioLine.release()).called(2);
      },
    );

    test(
      'Returns the first coin value when receiving two pulses',
      () async {
        final mockGpioLine = MockGpioLine();
        final mockRisingEdge = MockSignalEvent();
        final mockFallingEdge = MockSignalEvent();

        when(mockGpioLine.onEvent).thenAnswer(
          (_) => Stream.fromFutures([
            Future.value(mockFallingEdge),
            Future.delayed(
              const Duration(milliseconds: 29),
              () => mockRisingEdge,
            ),
            Future.delayed(
              const Duration(milliseconds: 29 + 104),
              () => mockFallingEdge,
            ),
            Future.delayed(
              const Duration(milliseconds: 29 + 104 + 29),
              () => mockRisingEdge,
            ),
          ]),
        );

        when(mockRisingEdge.edge).thenReturn(SignalEdge.rising);
        when(mockFallingEdge.edge).thenReturn(SignalEdge.falling);

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
