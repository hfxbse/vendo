import 'package:flutter/painting.dart';

class LabelDesign {
  final String? fontFamily;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;

  const LabelDesign({
    this.fontFamily,
    this.fontWeight,
    this.fontSize,
    this.color,
  });

  TextStyle toTextStyle() => TextStyle(
        fontSize: fontSize,
        color: color,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        height: 1,
      );
}
