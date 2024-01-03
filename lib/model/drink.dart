import 'package:flutter/widgets.dart';

import 'brand.dart';
import 'label_design.dart';

class Drink {
  final Brand brand;

  final String name;
  final LabelDesign labelDesign;

  final BoxDecoration? tileBackground;
  final BoxDecoration? purchaseBackground;
  final ImageProvider bottle;
  final ImageProvider bottleHead;

  final bool unifiedName;

  const Drink(
    this.name,
    this.bottle,
    this.bottleHead,
    this.brand, {
    this.tileBackground,
    this.purchaseBackground,
    this.unifiedName = false,
    this.labelDesign = const LabelDesign(
      fontSize: 40,
      fontWeight: FontWeight.w900,
    ),
  });
}
