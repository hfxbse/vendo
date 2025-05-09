import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vendo/payment/provider.dart';
import 'package:vendo/views/payment_process_bar.dart';

import 'package:vendo/model/drink.dart';

class PurchaseOverview extends StatelessWidget {
  const PurchaseOverview({required this.drink, required this.price, super.key});

  final Drink drink;
  final int price;

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
    final paymentProvider = GetIt.I<PaymentProvider>();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 10, child: drinkDisplay),
          Expanded(
            child: PaymentProcessBar(
              price: price,
              payment: paymentProvider.payment(
                price,
                onTransactionCompletion: Navigator.of(context).pop,
              ),
            ),
          )
        ],
      ),
    );
  }
}
