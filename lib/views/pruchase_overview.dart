import 'package:flutter/material.dart';

import '../model/drink.dart';

class PurchaseOverview extends StatelessWidget {
  const PurchaseOverview(this.drink, {super.key});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    final name =
        drink.unifiedName ? "${drink.brand.name} ${drink.name}" : drink.name;

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shadowColor: Colors.black,
        child: Container(height: 60),
      ),
    );
  }
}
