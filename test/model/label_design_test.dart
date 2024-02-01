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
        fontStyle: FontStyle.italic,
        letterSpacing: 1.5,
        wordSpacing: 2.5,
        height: 1.5,
        color: Colors.red,
        backgroundColor: Colors.green,
      );

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, labelDesign.fontFamily);
      expect(textStyle.fontSize, labelDesign.fontSize);
      expect(textStyle.fontWeight, labelDesign.fontWeight);
      expect(textStyle.fontStyle, labelDesign.fontStyle);
      expect(textStyle.letterSpacing, labelDesign.letterSpacing);
      expect(textStyle.wordSpacing, labelDesign.wordSpacing);
      expect(textStyle.height, labelDesign.height);
      expect(textStyle.color, labelDesign.color);
      expect(textStyle.backgroundColor, labelDesign.backgroundColor);
    });

    test('When no values are provided', () {
      const labelDesign = LabelDesign();

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, null);
      expect(textStyle.fontSize, null);
      expect(textStyle.fontWeight, null);
      expect(textStyle.fontStyle, null);
      expect(textStyle.letterSpacing, null);
      expect(textStyle.wordSpacing, null);
      expect(textStyle.height, null);
      expect(textStyle.color, null);
      expect(textStyle.backgroundColor, null);
    });
  });
}
