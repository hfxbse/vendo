import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/model/label_design.dart';

void main() {
  group('LabelDesign', () {
    test('toTextStyle should return correct TextStyle for valid LabelDesign',
        () {
      const labelDesign = LabelDesign(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.red);

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, 'Roboto');
      expect(textStyle.fontWeight, FontWeight.bold);
      expect(textStyle.fontSize, 16.0);
      expect(textStyle.color, Colors.red);
    });

    test(
        'toTextStyle should return correct TextStyle for null values in LabelDesign',
        () {
      const labelDesign = LabelDesign();

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, null);
      expect(textStyle.fontWeight, null);
      expect(textStyle.fontSize, null);
      expect(textStyle.color, null);
    });
  });
}
