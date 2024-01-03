import 'package:flutter/material.dart';
import 'package:vendo/model/drink.dart';

class DrinkListItem extends StatelessWidget {
  const DrinkListItem({super.key, required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 40 / 17,
      child: Ink(
        decoration: drink.tileBackground,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      drink.brand.name,
                      style: drink.brand.labelDesign.toTextStyle(),
                    ),
                    Text(
                      drink.name,
                      style: drink.labelDesign.toTextStyle(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Image(
                  fit: BoxFit.contain,
                  image: ResizeImage(drink.bottleHead, height: 300),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
