import 'package:flutter/widgets.dart';

import 'brand.dart';
import 'label_design.dart';

class Drink {
  final Brand brand;

  final String name;
  final LabelDesign labelDesign;

  final BoxDecoration? background;
  final ImageProvider bottle;
  final ImageProvider bottleHead;

  const Drink(
    this.name,
    this.bottle,
    this.bottleHead,
    this.brand, {
    this.background,
    this.labelDesign = const LabelDesign(
      fontSize: 40,
      fontWeight: FontWeight.w900,
    ),
  });
}
