import 'package:flutter/cupertino.dart';
import 'package:vendo/model/brand.dart';
import 'package:vendo/model/drink.dart';
import 'package:vendo/model/label_design.dart';

AssetImage drinkImage(String fileName) => AssetImage("drink_images/$fileName");

// region Paulaner Spezi
const paulanerSpeziBackgroundColor = Color(0xFF512d6d);

final paulanerSpeziBackgroundImage =
    drinkImage("${paulanerSpeziPrefix}_bubbles.png");

const paulanerSpeziPrefix = "paulaner_spezi";

const paulanerLabelDesign = LabelDesign(
  fontFamily: "Paulaner1634",
  fontWeight: FontWeight.bold,
  fontSize: 35,
  color: Color(0xFFefbd47),
);

final paulanerSpezi = Drink(
  "Spezi",
  drinkImage("${paulanerSpeziPrefix}_bottle.png"),
  drinkImage("${paulanerSpeziPrefix}_bottle_head.png"),
  const Brand("Paulaner", labelDesign: paulanerLabelDesign),
  labelDesign: paulanerLabelDesign,
  tileBackground: BoxDecoration(
    color: paulanerSpeziBackgroundColor,
    image: DecorationImage(
      image: paulanerSpeziBackgroundImage,
      alignment: const Alignment(1.3, 0),
      fit: BoxFit.fitHeight,
    ),
  ),
  purchaseBackground: BoxDecoration(
    color: paulanerSpeziBackgroundColor,
    image: DecorationImage(
        image: paulanerSpeziBackgroundImage,
        alignment: Alignment.center,
        fit: BoxFit.fitWidth),
  ),
  unifiedName: true,
);
// endregion Paulaner Spezi

// region Zwiefaltener Klosterbräu
String zwiefaltenerImagePrefix(String drink, String brand) {
  final brandPrefix = brand.toLowerCase().replaceAll(" ", "_");

  return "${brandPrefix}_${drink.toLowerCase()}";
}

Drink zwiefaltenerDesign(String drink, {String brand = "Zwiefaltener"}) {
  final prefix = zwiefaltenerImagePrefix(drink, brand);

  final background = BoxDecoration(
    image: DecorationImage(
      fit: BoxFit.cover,
      image: drinkImage("${prefix}_paper.jpg"),
    ),
  );

  return Drink(
    drink,
    drinkImage("${prefix}_bottle.png"),
    drinkImage("${prefix}_bottle_head.png"),
    Brand(
      brand,
      labelDesign: const LabelDesign(fontFamily: "Urbanist", fontSize: 16),
    ),
    labelDesign: const LabelDesign(fontFamily: "Grold", fontSize: 40),
    tileBackground: background,
    purchaseBackground: background,
  );
}
// endregion Zwiefaltener Klosterbräu

// Define all available drinks
final List<Drink> drinks = [
  paulanerSpezi,
  zwiefaltenerDesign("Edelperle"),
  zwiefaltenerDesign("Sorentia"),
  zwiefaltenerDesign("MixCola"),
  zwiefaltenerDesign("Johannisbeer", brand: "Zwiefaltener Albschorle"),
  Drink(
    "Apfelschorle",
    drinkImage("kaufland_apfelschorle_bottle.png"),
    drinkImage("kaufland_apfelschorle_bottle_head.png"),
    const Brand("Kaufland"),
    tileBackground: const BoxDecoration(color: Color(0xFFd2e7ba)),
    purchaseBackground: const BoxDecoration(color: Color(0xFFd2e7ba)),
  )
];
