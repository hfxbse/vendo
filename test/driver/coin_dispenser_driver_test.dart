import 'dart:async';

import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/driver/coin_dispenser_driver.dart';

import 'coin_dispenser_driver_test.mocks.dart';
import 'mock_gpio_line.dart';

const Duration circuitDelay = Duration(milliseconds: 500 + 50);

@GenerateMocks([SignalEvent])
void main() {
  const List<int> coinValues = [1, 2, 3];

  late MockGpioLine controlPin;
  late List<MockGpioLine> selectionPins;
  late CoinDispenserDriver dispenser;

  createMockEvent(
    SignalEdge edge,
    int timestampNanos,
    int offsetNanos,
  ) {
    final event = MockSignalEvent();
    when(event.edge).thenReturn(edge);
    when(event.timestampNanos).thenReturn(timestampNanos);

    return Future.delayed(
      Duration(microseconds: ((timestampNanos - offsetNanos) / 1000).toInt()),
      () => event,
    );
  }

  createMockEvents({int offsetNanos = 0}) {
    offsetNanos += offsetNanos > 0 ? 16624548532983 : 0;

    return [
      createMockEvent(
          SignalEdge.rising, 16624465656527 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.rising, 16624465723663 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.falling, 16624465752101 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.rising, 16624465806009 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.falling, 16624465843249 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.rising, 16624465911323 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.falling, 16624465965855 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.rising, 16624465994293 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.falling, 16624466075597 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.falling, 16624466131587 + offsetNanos, 16624465656527),
      createMockEvent(
          SignalEdge.rising, 16624548532983 + offsetNanos, 16624465656527),
    ];
  }

  createSingleDispenseEvents(Invocation _) =>
      Stream<SignalEvent>.fromFutures(createMockEvents()).asBroadcastStream();

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
    when(controlPin.onEvent).thenAnswer(createSingleDispenseEvents);

    dispenser.dispenseCoin(dispenser.coinValues.first);

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
    when(controlPin.onEvent).thenAnswer(createSingleDispenseEvents);

    dispenser.dispenseCoin(dispenser.coinValues.first);

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
        triggers: anyNamed('triggers'),
      )
    ]);
  });

  test(
    'Dispensation should be queued and not proceed without control feedback',
    () async {
      when(controlPin.onEvent).thenAnswer(
        (_) => StreamController<SignalEvent>().stream,
      );

      for (final coin in dispenser.coinValues) {
        dispenser.dispenseCoin(coin);
        dispenser.dispenseCoin(coin);
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
    final Map<int, List<bool>> selections = {
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

          when(controlPin.onEvent).thenAnswer(createSingleDispenseEvents);

          await dispenser.dispenseCoin(coin).timeout(circuitDelay);

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
      return Stream<SignalEvent>.fromFutures([
        ...createMockEvents(),
        ...createMockEvents(offsetNanos: 50 * 1000 * 1000)
      ]).asBroadcastStream();
    });

    await dispenser.dispenseCoin(coinValues.first).timeout(circuitDelay);

    verify(selectionPins[0].setValue(true)).called(1);
    verify(selectionPins[1].setValue(false)).called(greaterThanOrEqualTo(2));

    await dispenser.dispenseCoin(coinValues.last).timeout(circuitDelay);

    verify(selectionPins[0].setValue(true)).called(1);
    verify(selectionPins[1].setValue(true)).called(1);
  });

  test('Coin values list is immutable', () async {
    final original = dispenser.coinValues.toList(growable: false);
    try {
      dispenser.coinValues.sort((a, b) => b.compareTo(a));
    } on UnsupportedError catch (_) {
    } finally {
      expect(dispenser.coinValues, original);
    }
  });
}
