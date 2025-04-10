import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:get_it/get_it.dart';
import 'package:vendo/driver/coin_dispenser_driver.dart';
import 'package:vendo/driver/development_driver.dart';
import 'package:vendo/driver/drink_dispenser_driver.dart';
import 'package:vendo/driver/hx616_driver.dart';
import 'package:vendo/payment/provider.dart';
import 'package:vendo/views/drink_overview.dart';

void main() {
  final coinValues = [5, 10, 20, 50, 100, 200];

  final gpioHeader = getRaspberryGPIOHeader();
  final onRaspberryPi = gpioHeader != null;
  final developmentDriver =
      !onRaspberryPi ? DevelopmentDriver(coinValues) : null;

  assert(gpioHeader != null || developmentDriver != null);

  final coinSelector = onRaspberryPi
      ? HX616Driver(
          pulsePin: gpioHeader.lines[17],
          pulseActiveState: ActiveState.high,
          pulseBias: Bias.pullUp,
          pulseEndEdge: SignalEdge.rising,
          coinValues: coinValues,
        )
      : developmentDriver!;

  final coinDispenser = onRaspberryPi
      ? CoinDispenserDriver(
          controlPin: FlutterGpiod.instance.chips[0].lines[6],
          selectionPins: [
            gpioHeader.lines[13],
            gpioHeader.lines[19],
            gpioHeader.lines[26],
          ],
          coinValues: coinValues.sublist(1, coinValues.length - 1),
        )
      : developmentDriver!;

  final drinkDispenser = onRaspberryPi
      ? DrinkDispenserDriver.setup(
          forwardState: true,
          stepsPerRevolution: 200,
          stepPin: gpioHeader.lines[23],
          directionPin: gpioHeader.lines[24],
          enablePin: gpioHeader.lines[25],
        )
      : developmentDriver!;

  GetIt.I.registerSingleton<PaymentProvider>(
    PaymentProvider.fromSavefile(
      dataPath: Platform.environment['DATA_DIR'] ?? '/var/lib/vendo',
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ),
  );

  const app = DrinkOverview();
  runApp(
    developmentDriver != null
        ? KeyboardListener(
            app: app,
            driver: developmentDriver,
            acceptedCoins: coinValues,
          )
        : app,
  );
}

class KeyboardListener extends StatelessWidget {
  final Widget app;
  final DevelopmentDriver driver;
  final List<int> acceptedCoins;

  const KeyboardListener({
    super.key,
    required this.app,
    required this.driver,
    required this.acceptedCoins,
  });

  @override
  Widget build(BuildContext context) {
    assert(acceptedCoins.length <= 10);
    final slotIndexes = List<int>.generate(
      acceptedCoins.length,
      (i) => i,
      growable: false,
    );

    final bindings = {
      const CharacterActivator('d'): driver.completeDrinkDispensation,
      for (var slotIndex in slotIndexes)
        CharacterActivator(
          (slotIndex + 1 % 10).toString(),
        ): () => driver.insertCoinSlot(slotIndex)
    };

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(child: app),
    );
  }
}

GpioChip? getRaspberryGPIOHeader() {
  try {
    return FlutterGpiod.instance.chips.firstWhere(
      (chip) => chip.label == 'pinctrl-bcm2835',
      orElse: () => FlutterGpiod.instance.chips.firstWhere(
        (chip) => chip.label == 'pinctrl-bcm2711',
      ),
    );
  } catch (e) {
    if (!kDebugMode) rethrow;
    // ignore: avoid_print
    print("Failed to get Raspberry Pi GPIO Header: $e");
    // ignore: avoid_print
    print("Falling back to development mock driver");
    return null;
  }
}
