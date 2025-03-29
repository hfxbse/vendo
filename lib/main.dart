import 'package:flutter/material.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:get_it/get_it.dart';
import 'package:vendo/driver/coin_dispenser_driver.dart';
import 'package:vendo/driver/hx616_driver.dart';
import 'package:vendo/driver/drink_dispenser_driver.dart';
import 'package:vendo/payment/provider.dart';
import 'package:vendo/views/drink_list_item.dart';
import 'package:vendo/drinks.dart';
import 'package:vendo/views/pruchase_overview.dart';

import 'model/drink.dart';

void main() {
  final gpioHeader = FlutterGpiod.instance.chips.firstWhere(
    (chip) => chip.label == 'pinctrl-bcm2835',
    orElse: () => FlutterGpiod.instance.chips.firstWhere(
      (chip) => chip.label == 'pinctrl-bcm2711',
    ),
  );

  final coinValues = [0.05, 0.10, 0.20, 0.50, 1.00, 2.00];

  GetIt.I.registerSingleton<PaymentProvider>(
    PaymentProvider(
      coinSelector: HX616Driver(
        pulsePin: gpioHeader.lines[17],
        pulseActiveState: ActiveState.high,
        pulseBias: Bias.pullUp,
        pulseEndEdge: SignalEdge.rising,
        coinValues: coinValues,
      ),
      coinDispenser: CoinDispenserDriver(
        controlPin: FlutterGpiod.instance.chips[0].lines[6],
        selectionPins: [
          gpioHeader.lines[13],
          gpioHeader.lines[19],
          gpioHeader.lines[26],
        ],
        coinValues: coinValues.sublist(0, coinValues.length - 1),
      ),
      drinkDispenser: DrinkDispenserDriver.setup(
        forwardState: true,
        stepsPerRevolution: 200,
        stepPin: gpioHeader.lines[23],
        directionPin: gpioHeader.lines[24],
        enablePin: gpioHeader.lines[25],
      ),
    ),
  );

  runApp(const DrinkOverview());
}

class DrinkOverview extends StatelessWidget {
  const DrinkOverview({super.key});

  Widget _wrapDrinkListItem(Drink drink) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Builder(
          builder: (context) => InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PurchaseOverview(drink),
                ),
              );
            },
            child: DrinkListItem(drink: drink),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: drinks.map(_wrapDrinkListItem).toList(),
        ),
      ),
    );
  }
}
