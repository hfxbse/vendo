import 'package:flutter_gpiod/flutter_gpiod.dart';

class DrinkDispenser {
  final GpioLine stepPin;
  final GpioLine directionPin;
  final GpioLine enablePin;
  final int stepsPerRevolution;
  final bool forwardState;

  int currentPos = 0;

  DrinkDispenser._internal(
      {required this.stepPin,
      required this.directionPin,
      required this.enablePin,
      required this.stepsPerRevolution,
      required this.forwardState})
      : assert(stepPin != directionPin),
        assert(stepPin != enablePin),
        assert(enablePin != directionPin),
        assert(stepsPerRevolution > 0);

  factory DrinkDispenser.setup({
    required stepPin,
    required directionPin,
    required enablePin,
    required stepsPerRevolution,
    required forwardState,
  }) {
    for (final GpioLine pin in [stepPin, directionPin, enablePin]) {
      assert(!pin.requested);

      pin.requestOutput(
        consumer: "DRINK_DISPENSER",
        initialValue: false,
        activeState: ActiveState.high,
        outputMode: OutputMode.pushPull,
      );
    }

    return DrinkDispenser._internal(
      stepPin: stepPin,
      directionPin: directionPin,
      enablePin: enablePin,
      stepsPerRevolution: stepsPerRevolution,
      forwardState: forwardState,
    );
  }

  int get angle => (stepsPerRevolution / 3).toInt();

  Future<void> open() async {
    enablePin.setValue(true);
    directionPin.setValue(forwardState);

    await _step(angle);
  }

  Future<void> close() async {
    directionPin.setValue(!forwardState);

    await _step(angle);
    enablePin.setValue(false);
  }

  Future<void> _step(int stepCount) async {
    for (int i = 0; i < stepCount; ++i) {
      stepPin.setValue(true);
      await Future.delayed(const Duration(milliseconds: 1));
      stepPin.setValue(false);
    }
  }
}
