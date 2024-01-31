import 'package:flutter/material.dart';
import 'package:vendo/views/drink_list_item.dart';
import 'package:vendo/drinks.dart';
import 'package:vendo/views/pruchase_overview.dart';

import 'model/drink.dart';

void main() {
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
