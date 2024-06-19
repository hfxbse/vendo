import 'package:flutter/material.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:get_it/get_it.dart';
import 'package:vendo/coin_selector.dart';
import 'package:vendo/payment_provider.dart';
import 'package:vendo/views/drink_list_item.dart';
import 'package:vendo/drinks.dart';
import 'package:vendo/views/pruchase_overview.dart';

import 'model/drink.dart';

void main() {
  GetIt.I.registerSingleton<PaymentProvider>(
    PaymentProvider(
      CoinSelector(
        pulsePin: FlutterGpiod.instance.chips[0].lines[17],
        pulseActiveState: ActiveState.high,
        pulseBias: Bias.pullUp,
        pulseEndEdge: SignalEdge.rising,
        coinValues: [0.05, 0.10, 0.20, 0.50, 1.00, 2.00],
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
