import 'package:flutter/material.dart';
import 'package:flutter_gpiod/flutter_gpiod.dart';
import 'package:vendo/coin_selector.dart';
import 'package:vendo/payment_provider.dart';
import 'package:vendo/views/payment_process_bar.dart';

import '../model/drink.dart';

class PurchaseOverview extends StatelessWidget {
  const PurchaseOverview(this.drink, {super.key});

  final Drink drink;

  Widget get drinkDisplay {
    final name =
        drink.unifiedName ? "${drink.brand.name} ${drink.name}" : drink.name;

    return Container(
      decoration: drink.purchaseBackground,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!drink.unifiedName)
                      Text(
                        drink.brand.name,
                        style: drink.brand.labelDesign.toTextStyle(),
                      ),
                    Text(name, style: drink.labelDesign.toTextStyle()),
                  ],
                ),
              ),
            ),
            Expanded(flex: 4, child: Image(image: drink.bottle)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const price = 0.6;
    final coinSelector = CoinSelector(
      pulsePin: FlutterGpiod.instance.chips[0].lines[17],
      pulseActiveState: ActiveState.high,
      pulseBias: Bias.pullUp,
      pulseEndEdge: SignalEdge.rising,
        coinValues: [0.05, 0.10, 0.20, 0.50, 1.00, 2.00]);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 10, child: drinkDisplay),
          Expanded(
            child: PaymentProcessBar(
              PaymentProvider(coinSelector).payment(price),
              price,
            ),
          )
        ],
      ),
    );
  }
}
