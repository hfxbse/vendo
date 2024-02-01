import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/model/label_design.dart';

void main() {
  group('TextStyle should be created from LabelDesign', () {
    test('When values are provided', () {
      const labelDesign = LabelDesign(
        fontFamily: "Roboto",
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.red,
      );

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, labelDesign.fontFamily);
      expect(textStyle.fontSize, labelDesign.fontSize);
      expect(textStyle.fontWeight, labelDesign.fontWeight);
      expect(textStyle.color, labelDesign.color);
    });

    test('When no values are provided', () {
      const labelDesign = LabelDesign();

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, labelDesign.fontFamily);
      expect(textStyle.fontSize, labelDesign.fontSize);
      expect(textStyle.fontWeight, labelDesign.fontWeight);
      expect(textStyle.color, labelDesign.color);
    });
  });
}
