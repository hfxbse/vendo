import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/model/label_design.dart';

void main() {
  group('TextStyle should be created from LabelDesign', () {
    test('When values are provided', () {
      const fontFamily = "Roboto";
      const fontWeight = FontWeight.w100;
      const double fontSize = 100;
      const color = Colors.pink;

      final textStyle = const LabelDesign(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
        fontFamily: fontFamily,
      ).toTextStyle();

      expect(textStyle.fontFamily, fontFamily);
      expect(textStyle.fontWeight, fontWeight);
      expect(textStyle.fontSize, fontSize);
      expect(textStyle.color, color);
    });

    test('When no values are provided', () {
      final textStyle = const LabelDesign().toTextStyle();

      expect(textStyle, anything);
    });
  });
}
