import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';

import 'coin_selector_test.mocks.dart';

@GenerateMocks([GpioLine, LineInfo])
void main() {
  group('Coin selector should setup GPIOs', () {
    final pin = MockGpioLine();
    final lineInfo = MockLineInfo();

    when(lineInfo.name).thenReturn("Mock Pin");
    when(pin.info).thenReturn(lineInfo);

    for (var coinSelector in [
      CoinSelector(
        pulsePin: pin,
        pulseBias: Bias.pullUp,
        pulseActiveState: ActiveState.high,
        pulseEndEdge: SignalEdge.rising,
      ),
      CoinSelector(
        pulsePin: pin,
        pulseBias: Bias.pullDown,
        pulseActiveState: ActiveState.low,
        pulseEndEdge: SignalEdge.falling,
      )
    ]) {
      test(coinSelector.toString(), () {
        coinSelector.activate();

        verify(coinSelector.pulsePin.requestInput(
          consumer: "COIN_SELECTOR",
          activeState: coinSelector.pulseActiveState,
          bias: coinSelector.pulseBias,
          triggers: {coinSelector.pulseEndEdge},
        )).called(1);
      });
    }
  });

  test('Coin selector should release GPIOs', () {
    final pin = MockGpioLine();

    final coinSelector = CoinSelector(
      pulsePin: pin,
      pulseBias: Bias.disable,
      pulseActiveState: ActiveState.high,
      pulseEndEdge: SignalEdge.rising,
    );

    coinSelector.deactivate();

    verify(pin.release()).called(1);
  });

  group('Coin selector only has pulse end edges in stream', () {
    final pin = MockGpioLine();

    when(pin.onEvent).thenAnswer(
      (_) => Stream.fromIterable(
        [
          SignalEdge.rising,
          SignalEdge.falling,
          SignalEdge.falling,
          SignalEdge.rising,
        ].map(
          (edge) => SignalEvent(
            edge,
            0,
            Duration.zero,
            DateTime.fromMicrosecondsSinceEpoch(0),
          ),
        ),
      ),
    );

    [SignalEdge.rising, SignalEdge.falling].map((edge) {
      return CoinSelector(
        pulsePin: pin,
        pulseBias: Bias.disable,
        pulseActiveState: ActiveState.high,
        pulseEndEdge: edge,
      );
    }).forEach((coinSelector) {
      test(
        coinSelector.pulseEndEdge.toString(),
        () {
          expect(
            coinSelector.events,
            emits(
              (SignalEvent event) => event.edge == coinSelector.pulseEndEdge,
            ),
          );
        },
      );
    });
  });
}
