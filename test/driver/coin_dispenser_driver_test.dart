import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/driver/coin_dispenser_driver.dart';

import 'mock_gpio_line.dart';

import 'coin_dispenser_driver_test.mocks.dart';

const Duration circuitDelay = Duration(milliseconds: 50);

@GenerateMocks([SignalEvent])
void main() {
  const List<double> coinValues = [1, 2, 3];

  late MockGpioLine controlPin;
  late List<MockGpioLine> selectionPins;
  late CoinDispenserDriver dispenser;

  setUp(() {
    controlPin = MockGpioLine();
    selectionPins = [MockGpioLine(), MockGpioLine()];

    for (final pin in [controlPin, ...selectionPins]) {
      when(pin.requested).thenReturn(false);
    }

    dispenser = CoinDispenserDriver(
      controlPin: controlPin,
      selectionPins: selectionPins,
      coinValues: coinValues,
    );
  });

  test('Selection GPIOs should setup before dispensation', () async {
    when(controlPin.onEvent).thenAnswer(
      (_) => StreamController<SignalEvent>().stream,
    );

    dispenser.dispense(dispenser.coinValues.first);

    await Future.delayed(circuitDelay);

    for (final pin in selectionPins) {
      verify(pin.requestOutput(
        consumer: anyNamed('consumer'),
        bias: anyNamed('bias'),
        activeState: ActiveState.high,
        outputMode: OutputMode.pushPull,
        initialValue: false,
      )).called(1);
    }
  });

  test('Control pin should setup before dispensation', () async {
    when(controlPin.onEvent).thenAnswer(
      (_) => StreamController<SignalEvent>().stream,
    );

    dispenser.dispense(dispenser.coinValues.first);

    await Future.delayed(circuitDelay);

    verifyInOrder([
      controlPin.requestOutput(
        consumer: anyNamed('consumer'),
        initialValue: true,
        activeState: ActiveState.low,
        outputMode: OutputMode.pushPull,
      ),
      controlPin.setValue(false),
      controlPin.release(),
      controlPin.requestInput(
        consumer: anyNamed('consumer'),
        bias: Bias.disable,
        activeState: ActiveState.high,
        triggers: {SignalEdge.rising},
      )
    ]);
  });

  test('Control pin is released after dispensation', () async {
    when(controlPin.onEvent).thenAnswer((_) {
      final event = MockSignalEvent();
      when(event.edge).thenReturn(SignalEdge.rising);

      return Stream.value(event);
    });

    await dispenser.dispense(dispenser.coinValues.first).timeout(circuitDelay);

    verifyInOrder([
      controlPin.requestInput(
        consumer: anyNamed('consumer'),
        triggers: anyNamed('triggers'),
        activeState: anyNamed('activeState'),
        bias: anyNamed('bias'),
      ),
      controlPin.release(),
    ]);
  });

  test(
    'Dispensation should be queued and not proceed without control feedback',
    () async {
      when(controlPin.onEvent).thenAnswer(
        (_) => StreamController<SignalEvent>().stream,
      );

      for (final coin in dispenser.coinValues) {
        dispenser.dispense(coin);
        dispenser.dispense(coin);
      }

      await Future.delayed(circuitDelay);

      verify(
        controlPin.requestInput(
          consumer: anyNamed('consumer'),
          bias: anyNamed('bias'),
          activeState: anyNamed('activeState'),
          triggers: anyNamed('triggers'),
        ),
      ).called(1);

      verify(selectionPins[0].setValue(true)).called(1);
      verify(selectionPins[0].setValue(false)).called(1);
    },
  );

  group('Applies correct coin dispersion pin selection', () {
    final Map<double, List<bool>> selections = {
      coinValues[0]: [true, false],
      coinValues[1]: [false, true],
      coinValues[2]: [true, true],
    };

    String prettyPrintState(List<bool> state) {
      return (state.map((bool state) => state ? 1 : 0)).toString();
    }

    selections.forEach((coin, pinStates) {
      test(
        'Coin value $coin: ${prettyPrintState(pinStates)}',
        () async {
          assert(pinStates.length == dispenser.selectionPins.length);

          when(controlPin.onEvent).thenAnswer((_) {
            final event = MockSignalEvent();
            when(event.edge).thenReturn(SignalEdge.rising);

            return Stream.value(event);
          });

          await dispenser.dispense(coin).timeout(circuitDelay);

          for (var position = 0; position < pinStates.length; ++position) {
            verifyInOrder([
              selectionPins[position].setValue(false),
              selectionPins[position].setValue(pinStates[position]),
            ]);
          }
        },
      );
    });
  });

  test('Supports sequential dispensation', () async {
    when(controlPin.onEvent).thenAnswer((_) {
      final event = MockSignalEvent();
      when(event.edge).thenReturn(SignalEdge.rising);

      return Stream.fromIterable([event, event]);
    });

    await dispenser.dispense(coinValues.first).timeout(circuitDelay);

    verify(selectionPins[0].setValue(true)).called(1);
    verify(selectionPins[1].setValue(false)).called(2);

    await dispenser.dispense(coinValues.last).timeout(circuitDelay);

    verify(selectionPins[0].setValue(true)).called(1);
    verify(selectionPins[1].setValue(true)).called(1);
  });
}
