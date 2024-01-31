import 'toTextStyle.welltested_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package:vendo/model/label_design.dart';
import 'package:vendo/model/label_design.dart';

@GenerateMocks([LabelDesign])
void main() {
  group('LabelDesign', () {
    test('toTextStyle should return correct TextStyle for valid LabelDesign',
        () {
      final labelDesign = MockLabelDesign();
      when(labelDesign.fontFamily).thenReturn('Roboto');
      when(labelDesign.fontWeight).thenReturn(FontWeight.bold);
      when(labelDesign.fontSize).thenReturn(16.0);
      when(labelDesign.color).thenReturn(Colors.red);

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, 'Roboto');
      expect(textStyle.fontWeight, FontWeight.bold);
      expect(textStyle.fontSize, 16.0);
      expect(textStyle.color, Colors.red);
    });

    test(
        'toTextStyle should return correct TextStyle for null values in LabelDesign',
        () {
      final labelDesign = MockLabelDesign();
      when(labelDesign.fontFamily).thenReturn(null);
      when(labelDesign.fontWeight).thenReturn(null);
      when(labelDesign.fontSize).thenReturn(null);
      when(labelDesign.color).thenReturn(null);

      final textStyle = labelDesign.toTextStyle();

      expect(textStyle.fontFamily, null);
      expect(textStyle.fontWeight, null);
      expect(textStyle.fontSize, null);
      expect(textStyle.color, null);
    });
  });
}
