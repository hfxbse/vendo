import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'MockGpioLine.mocks.dart';

@GenerateMocks([LineInfo])
class MockGpioLine extends Mock implements GpioLine {
  @override
  void requestInput({
    required String? consumer,
    Bias? bias,
    ActiveState? activeState = ActiveState.high,
    Set<SignalEdge>? triggers = const {},
  }) {
    super.noSuchMethod(Invocation.method(#requestInput, [], {
      #consumer: consumer,
      #bias: bias,
      #activeState: activeState,
      #triggers: triggers
    }));
  }

  @override
  get onEvent => super.noSuchMethod(
        Invocation.getter(#onEvent),
        returnValue: const Stream<SignalEvent>.empty(),
      );

  @override
  get info {
    final info = MockLineInfo();
    when(info.name).thenReturn('Mock pin');

    return super.noSuchMethod(
      Invocation.getter(#info),
      returnValueForMissingStub: info,
    );
  }
}
