import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/model/brand.dart';
import 'package:vendo/model/drink.dart';
import 'package:vendo/views/drink_list_item.dart';

void main() {
  late MemoryImage bottleImage;
  late MemoryImage bottleHeadImage;

  setUp(() async {
    final testImage = await createTestImage(width: 156, height: 256);
    final testHeadImage = await createTestImage(width: 156, height: 256);

    final bottleImageBytes = await testImage.toByteData();
    final bottleHeadImageBytes = await testHeadImage.toByteData();

    bottleImage = MemoryImage(bottleImageBytes!.buffer.asUint8List());
    bottleHeadImage = MemoryImage(bottleHeadImageBytes!.buffer.asUint8List());
  });

  testWidgets("DrinkListItem should render correctly", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkListItem(
              drink: Drink(
            "Coke",
            bottleImage,
            bottleHeadImage,
            const Brand("Coca Cola"),
            tileBackground: const BoxDecoration(color: Colors.red),
          )),
        ),
      ),
    );

    expect(find.text("Coke"), findsOneWidget);
    expect(find.text("Coca Cola"), findsOneWidget);

    await tester.pumpAndSettle();

    // golden image testing
    await expectLater(
      find.byType(DrinkListItem),
      matchesGoldenFile('goldens/drink_list_item.png'),
    );
  });
}
