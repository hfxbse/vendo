import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';

@GenerateMocks([GpioLine, LineInfo])
void main() {
  group('CoinSelector', () {
    test(
      'toString returns correct string representation',
      () {
        final mockGpioLine = MockGpioLine();
        final mockLineInfo = MockLineInfo();
        when(mockGpioLine.info).thenReturn(mockLineInfo);
        when(mockLineInfo.name).thenReturn('testLine');

        final coinSelector = CoinSelector(
          pulsePin: mockGpioLine,
          pulseBias: Bias.pullDown,
          pulseActiveState: ActiveState.low,
          pulseEndEdge: SignalEdge.rising,
          coinValues: [1.0, 2.0, 3.0],
        );

        expect(
          coinSelector.toString(),
          'CoinSelector{#pulsePin: testLine, pulseBias: Bias.pullDown, pulseActiveState: ActiveState.low, pulseEndEdge: SignalEdge.rising}',
        );
      },
    );
  });
}
