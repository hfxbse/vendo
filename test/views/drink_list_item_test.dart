import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendo/model/brand.dart';
import 'package:vendo/model/drink.dart';
import 'package:vendo/views/drink_list_item.dart';

void main() {
  late MemoryImage bottleImage;
  late MemoryImage bottleHeadImage;

  setUp(() async {
    Future<MemoryImage> createTestImageProvider({
      int width = 1,
      int height = 1,
      bool cache = true,
    }) async {
      final image = await createTestImage(
        width: width,
        height: height,
        cache: cache,
      );

      return MemoryImage((await image.toByteData())!.buffer.asUint8List());
    }

    bottleHeadImage = await createTestImageProvider(width: 156, height: 250);
    bottleImage = await createTestImageProvider(width: 156, height: 600);
  });

  testWidgets('Should renders drink correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrinkListItem(
            drink: Drink(
              "Long name",
              bottleImage,
              bottleHeadImage,
              const Brand("Long brand"),
              tileBackground: const BoxDecoration(color: Colors.green),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    await expectLater(
      find.byType(DrinkListItem),
      matchesGoldenFile('drink_list_item.png'),
    );
  });
}
