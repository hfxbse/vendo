import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:vendo/payment/coin_dispenser.dart';
import 'package:vendo/payment/coin_selector.dart';
import 'package:vendo/payment/drink_dispenser.dart';
import 'package:vendo/payment/provider.dart';

import 'provider_test.mocks.dart';

class Functions {
  void callback() {}
}

String uniqueTempDirPath() {
  const uuid = Uuid();
  return p.join(
    Directory.systemTemp.absolute.path,
    "vendo-test",
    uuid.v4().toString(),
  );
}

class JsonFileStates {
  const JsonFileStates(
      {required this.initialContent, required this.expectedContent});

  final String? initialContent;
  final String expectedContent;
}

@GenerateMocks([CoinSelector, CoinDispenser, DrinkDispenser, Functions])
void main() {
  test('Payed amount should add up', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    final coins = Stream.fromIterable([5, 10, 20, 50, 100, 200]);

    when(coinSelector.coins).thenAnswer((_) => coins);
    when(coinDispenser.coinValues).thenAnswer((_) => [1]);

    final stream = PaymentProvider.fromSavefile(
      dataPath: uniqueTempDirPath(),
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ).payment(420).timeout(const Duration(milliseconds: 100));

    expect(
      stream,
      emitsInOrder([5, 15, 35, 85, 185, 385]),
    );
  });

  test('Stops counting after price amount is reached', () {
    final coinSelector = MockCoinSelector();
    final coinDispenser = MockCoinDispenser();
    final drinkDispenser = MockDrinkDispenser();

    final coins = Stream.fromIterable([5, 10, 20, 50, 100, 200]);

    when(coinSelector.coins).thenAnswer((_) => coins);
    when(coinDispenser.coinValues).thenAnswer((_) => [1]);

    final stream = PaymentProvider.fromSavefile(
      dataPath: uniqueTempDirPath(),
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    ).payment(50).timeout(const Duration(milliseconds: 100));

    expect(
      stream,
      emitsInOrder([5, 15, 35, 85]),
    );
  });

  group('Change dispense', () {
    late MockCoinSelector coinSelector;
    late MockCoinDispenser coinDispenser;
    late MockDrinkDispenser drinkDispenser;
    late String dataPath;

    setUp(() {
      dataPath = uniqueTempDirPath();
      coinSelector = MockCoinSelector();
      coinDispenser = MockCoinDispenser();
      drinkDispenser = MockDrinkDispenser();

      when(coinDispenser.dispenseCoin(any)).thenAnswer(
        (_) => Future.sync(() {}),
      );
    });

    setUpSaveFile(String content) async {
      final file = File(p.join(dataPath, 'available_coins.json'));

      await file.create(
        recursive: true,
        exclusive: true,
      );

      await file.writeAsString(content);
    }

    group('Price not met', () {
      setUp(() {
        when(coinDispenser.coinValues).thenAnswer((_) => [1]);
      });

      test(
        'Returns payed amount if payment is canceled and price not met',
        () async {
          const price = 798;
          const payed = 42;
          final coins = Stream.fromIterable([payed]);

          when(coinSelector.coins).thenAnswer((_) => coins);
          await setUpSaveFile('{"1": $payed}');

          final stream = PaymentProvider.fromSavefile(
            dataPath: dataPath,
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verify(coinDispenser.dispenseCoin(1)).called(payed);
          }
        },
      );

      test(
        'Returns nothing if payment is canceled and nothing has been payed',
        () async {
          const price = 465;
          final coins = Stream.fromIterable(List<int>.empty());

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider.fromSavefile(
            dataPath: uniqueTempDirPath(),
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verifyNever(coinDispenser.dispenseCoin(any));
          }
        },
      );
    });

    group('Price met', () {
      setUp(() {
        when(coinDispenser.coinValues).thenAnswer((_) => [1]);
      });

      test(
        'Returns correct change amount if price is exceeded',
        () async {
          const price = 50;
          const change = 85;
          final coins = Stream.fromIterable([price + change]);

          when(coinSelector.coins).thenAnswer((_) => coins);
          await setUpSaveFile('{"1": $change}');

          final stream = PaymentProvider.fromSavefile(
            dataPath: dataPath,
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verify(coinDispenser.dispenseCoin(1)).called(change);
          }
        },
      );

      test(
        'Returns nothing if price is exactly matched',
        () async {
          const price = 34;
          final coins = Stream.fromIterable([price]);

          when(coinSelector.coins).thenAnswer((_) => coins);

          final stream = PaymentProvider.fromSavefile(
            dataPath: uniqueTempDirPath(),
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          ).payment(price).timeout(const Duration(milliseconds: 100));

          try {
            await stream.last;
          } on TimeoutException catch (_) {
          } finally {
            verifyNever(coinDispenser.dispenseCoin(any));
          }
        },
      );
    });

    group('Book keeping', () {
      group('Save file validation', () {
        test('Throws exception if file is invalid', () async {
          await setUpSaveFile('{ Not a JSON object }');

          expect(() {
            PaymentProvider.fromSavefile(
              coinSelector: coinSelector,
              coinDispenser: coinDispenser,
              drinkDispenser: drinkDispenser,
              dataPath: dataPath,
            );
          }, throwsA(isA<FormatException>()));
        });

        group('Throws exception if key or value is not an integer', () {
          const Map<String, String> testCases = {
            'Key as integer string with prefix text': '{ "f1": 1 }',
            'Key as integer string with postfix text': '{ "1d": 1 }',
            'Key as double string': '{ "1.0": 1 }',
            'Value as integer string ': '{ "1": "1" }',
            'Value as text string ': '{ "1": "should fail" }',
            'Value as double': '{ "1": 1.0 }',
          };

          for (final testCase in testCases.entries) {
            test(testCase.key, () async {
              await setUpSaveFile(testCase.value);

              expect(() {
                PaymentProvider.fromSavefile(
                  coinSelector: coinSelector,
                  coinDispenser: coinDispenser,
                  drinkDispenser: drinkDispenser,
                  dataPath: dataPath,
                );
              }, throwsA(isA<FormatException>()));
            });
          }
        });

        test('Throws if unexpected coin value is present', () async {
          when(coinDispenser.coinValues).thenAnswer((_) => [1]);

          await setUpSaveFile('{"2": 1}');

          expect(() {
            PaymentProvider.fromSavefile(
              coinSelector: coinSelector,
              coinDispenser: coinDispenser,
              drinkDispenser: drinkDispenser,
              dataPath: dataPath,
            );
          }, throwsA(isA<StateError>()));
        });

        group('Throws if value is negative', () {
          setUp(() {
            when(coinDispenser.coinValues).thenAnswer((_) => [1]);
          });

          const Map<String, String> testCases = {
            'Coin value': '{"-1": 1}',
            'Coin count': '{"1": -1}',
          };

          for (final testCase in testCases.entries) {
            test(testCase.key, () async {
              await setUpSaveFile(testCase.value);

              expect(() {
                PaymentProvider.fromSavefile(
                  coinSelector: coinSelector,
                  coinDispenser: coinDispenser,
                  drinkDispenser: drinkDispenser,
                  dataPath: dataPath,
                );
              }, throwsA(isA<RangeError>()));
            });
          }
        });
      });

      group('Save file updating', () {
        setUp(() {
          when(coinDispenser.coinValues).thenAnswer((_) => [1, 2]);
        });

        Future<String> readSaveFile() =>
            File(p.join(dataPath, 'available_coins.json')).readAsString();

        group('Has correct state after transaction is completed', () {
          const Map<String, JsonFileStates> testCases = {
            "No preexisting save file": JsonFileStates(
              initialContent: null,
              expectedContent: '{"1":2,"2":1}',
            ),
            "Preexisting save file": JsonFileStates(
              initialContent: '{"1":2,"2":0}',
              expectedContent: '{"1":4,"2":1}',
            ),
          };

          for (final testCase in testCases.entries) {
            test(testCase.key, () async {
              const price = 8;
              final coins = Stream.fromIterable([1, 2, 1, 4]);
              when(coinSelector.coins).thenAnswer((_) => coins);

              if (testCase.value.initialContent != null) {
                await setUpSaveFile(testCase.value.initialContent!);
              }

              final payment = PaymentProvider.fromSavefile(
                coinSelector: coinSelector,
                coinDispenser: coinDispenser,
                drinkDispenser: drinkDispenser,
                dataPath: dataPath,
              ).payment(price).timeout(const Duration(milliseconds: 100));

              try {
                await payment.last;
              } on TimeoutException catch (_) {
              } finally {
                expect(await readSaveFile(), testCase.value.expectedContent);
              }
            });
          }
        });

        group('Has correct state after transaction is canceled', () {
          const Map<String, JsonFileStates> testCases = {
            "No preexisting save file": JsonFileStates(
              initialContent: null,
              expectedContent: '{"1":0,"2":0}',
            ),
            "Preexisting save file": JsonFileStates(
              initialContent: '{"1":2,"2":5}',
              expectedContent: '{"1":2,"2":3}',
            )
          };

          for (final testCase in testCases.entries) {
            test(testCase.key, () async {
              const price = 8;
              final coins = Stream.fromIterable([1, 2, 4]);
              when(coinSelector.coins).thenAnswer((_) => coins);

              if (testCase.value.initialContent != null) {
                await setUpSaveFile(testCase.value.initialContent!);
              }

              final payment = PaymentProvider.fromSavefile(
                coinSelector: coinSelector,
                coinDispenser: coinDispenser,
                drinkDispenser: drinkDispenser,
                dataPath: dataPath,
              ).payment(price).timeout(const Duration(milliseconds: 100));

              try {
                await payment.last;
              } on TimeoutException catch (_) {
              } finally {
                expect(await readSaveFile(), testCase.value.expectedContent);
              }
            });
          }
        });
      });
    });
  });

  group('Drink dispense', () {
    late MockCoinDispenser coinDispenser;
    late MockDrinkDispenser drinkDispenser;
    late MockFunctions mockCallback;

    setUp(() {
      coinDispenser = MockCoinDispenser();
      drinkDispenser = MockDrinkDispenser();
      mockCallback = MockFunctions();

      when(coinDispenser.dispenseCoin(any))
          .thenAnswer((_) => Future.sync(() {}));
      when(coinDispenser.coinValues).thenAnswer((_) => [1]);
    });

    group("Price fully paid", () {
      const price = 50;
      final coins = Stream.fromIterable([price]);

      final coinSelector = MockCoinSelector();
      when(coinSelector.coins).thenAnswer((_) => coins);

      stream() => PaymentProvider.fromSavefile(
            dataPath: uniqueTempDirPath(),
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          )
              .payment(price, onTransactionCompletion: mockCallback.callback)
              .timeout(const Duration(milliseconds: 100));

      test('Does call the transaction completion callback', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verify(mockCallback.callback()).called(1);
        }
      });

      test('Does start the drink dispensation', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verify(drinkDispenser.dispenseDrink()).called(1);
        }
      });
    });

    group("Transaction canceled", () {
      const price = 34;
      final coins = Stream.fromIterable([price - 1]);

      final coinSelector = MockCoinSelector();
      when(coinSelector.coins).thenAnswer((_) => coins);

      stream() => PaymentProvider.fromSavefile(
            dataPath: uniqueTempDirPath(),
            coinSelector: coinSelector,
            coinDispenser: coinDispenser,
            drinkDispenser: drinkDispenser,
          )
              .payment(price, onTransactionCompletion: mockCallback.callback)
              .timeout(const Duration(milliseconds: 100));

      test('Does not call the transaction completion callback', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verifyNever(mockCallback.callback());
        }
      });

      test('Does not start the drink dispensation', () async {
        try {
          await stream().last;
        } on TimeoutException catch (_) {
        } finally {
          verifyNever(drinkDispenser.dispenseDrink());
        }
      });
    });
  });
}
