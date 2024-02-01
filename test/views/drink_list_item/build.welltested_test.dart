import 'build.welltested_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/model/brand.dart';
import 'package:vendo/model/drink.dart';
import 'package:vendo/model/label_design.dart';
import 'package:vendo/views/drink_list_item.dart';

@GenerateMocks([Drink, Brand, LabelDesign, BuildContext])
void main() {
  late MemoryImage testImage;

  setUp(() async {
    final image = await createTestImage(
      width: 156,
      height: 250,
      cache: true,
    );

    testImage = MemoryImage((await image.toByteData())!.buffer.asUint8List());
  });

  group(
    'DrinkListItem',
    () {
      testWidgets(
        'should display drink brand name and drink name',
        (WidgetTester tester) async {
          final mockDrink = MockDrink();
          final mockBrand = MockBrand();
          final mockLabelDesign = MockLabelDesign();

          when(mockDrink.brand).thenReturn(mockBrand);
          when(mockBrand.name).thenReturn('Coca Cola');
          when(mockDrink.name).thenReturn('Coke');
          when(mockDrink.labelDesign).thenReturn(mockLabelDesign);
          when(mockDrink.tileBackground).thenReturn(
            const BoxDecoration(color: Colors.red),
          );
          when(mockDrink.bottleHead).thenReturn(testImage);

          when(mockBrand.labelDesign).thenReturn(mockLabelDesign);
          when(mockLabelDesign.toTextStyle()).thenReturn(const TextStyle());

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: DrinkListItem(drink: mockDrink),
            ),
          ));

          expect(find.text('Coca Cola'), findsOneWidget);
          expect(find.text('Coke'), findsOneWidget);
        },
      );

      testWidgets(
        'should handle long drink brand name and drink name',
        (WidgetTester tester) async {
          final mockDrink = MockDrink();
          final mockBrand = MockBrand();
          final mockLabelDesign = MockLabelDesign();

          when(mockDrink.brand).thenReturn(mockBrand);
          when(mockBrand.name).thenReturn(
            'Coca Cola Coca Cola Coca Cola Coca Cola Coca Cola',
          );
          when(mockDrink.name).thenReturn(
            'Coke Coke Coke Coke Coke Coke Coke Coke Coke Coke',
          );
          when(mockDrink.tileBackground).thenReturn(
            const BoxDecoration(color: Colors.red),
          );
          when(mockDrink.bottleHead).thenReturn(testImage);
          when(mockDrink.labelDesign).thenReturn(mockLabelDesign);
          when(mockBrand.labelDesign).thenReturn(mockLabelDesign);
          when(mockLabelDesign.toTextStyle()).thenReturn(const TextStyle());

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: DrinkListItem(drink: mockDrink),
            ),
          ));

          expect(
            find.text('Coca Cola Coca Cola Coca Cola Coca Cola Coca Cola'),
            findsOneWidget,
          );
          expect(
            find.text('Coke Coke Coke Coke Coke Coke Coke Coke Coke Coke'),
            findsOneWidget,
          );
        },
      );
    },
  );
}
