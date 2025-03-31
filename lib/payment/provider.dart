import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'coin_dispenser.dart';
import 'coin_selector.dart';
import 'drink_dispenser.dart';

class PaymentProvider {
  PaymentProvider._internal({
    required this.saveFile,
    required this.availableCoins,
    required this.coinSelector,
    required this.coinDispenser,
    required this.drinkDispenser,
  });

  static File _getSaveFile(String dataPath) {
    final saveFile = File(p.join(dataPath, 'available_coins.json'));
    if (kDebugMode) print("Save directory is ${saveFile.absolute.path}");

    saveFile.createSync(recursive: true, exclusive: false);
    return saveFile;
  }

  static Map<int, int> _readSaveFile(File saveFile) {
    final content = saveFile.readAsStringSync();
    final Map<String, dynamic> rawEntries =
        content.isNotEmpty ? jsonDecode(content) : {};

    return rawEntries.map((key, coinCount) {
      final coinValue = int.tryParse(key, radix: 10);

      if (coinValue == null || coinCount is! int) {
        final path = saveFile.absolute.path;

        throw FormatException(
          "Save file $path contains values other than integers: "
          "\"$key\": \"$coinCount\"",
        );
      } else if (coinValue < 0) {
        throw RangeError(
          "Coin value cannot be negative: $coinValue",
        );
      } else if (coinCount < 0) {
        throw RangeError(
          "Coin count for coin value $coinValue cannot be negative: $coinCount",
        );
      }

      return MapEntry(coinValue, coinCount);
    });
  }

  factory PaymentProvider.fromSavefile({
    required CoinSelector coinSelector,
    required CoinDispenser coinDispenser,
    required DrinkDispenser drinkDispenser,
    required String dataPath,
  }) {
    final saveFile = _getSaveFile(dataPath);
    final Map<int, int> availableCoins = _readSaveFile(saveFile);

    for (final coin in availableCoins.keys) {
      if (!coinDispenser.coinValues.contains(coin)) {
        final path = saveFile.absolute.path;
        throw StateError(
          "Save file $path contains unexpected entry for coin value $coin",
        );
      }
    }

    for (final coin in coinDispenser.coinValues) {
      availableCoins.putIfAbsent(coin, () => 0);
    }

    return PaymentProvider._internal(
      saveFile: saveFile,
      availableCoins: availableCoins,
      coinSelector: coinSelector,
      coinDispenser: coinDispenser,
      drinkDispenser: drinkDispenser,
    );
  }

  final File saveFile;
  final Map<int, int> availableCoins;
  final CoinSelector coinSelector;
  final CoinDispenser coinDispenser;
  final DrinkDispenser drinkDispenser;

  bool _fullyPayed({required int price, required int payed}) => payed >= price;

  Stream<int> payment(int price, {Function()? onTransactionCompletion}) {
    int payed = 0;

    final controller = StreamController<int>();

    late final StreamSubscription subscription;

    subscription = coinSelector.coins.listen((coin) async {
      if (controller.isClosed) {
        subscription.cancel();
        return;
      }

      payed += coin;
      controller.add(payed);
      await _updateAvailableCoins(coin, 1);

      if (_fullyPayed(price: price, payed: payed)) controller.close();
    });

    controller.onCancel = () async {
      await subscription.cancel();

      final fullyPayed = _fullyPayed(price: price, payed: payed);

      await Future.wait([
        _dispenseChange(fullyPayed ? payed - price : payed),
        if (fullyPayed)
          drinkDispenser.dispenseDrink()
            ..then((_) {
              if (onTransactionCompletion != null) onTransactionCompletion();
            })
      ]);
    };

    return controller.stream;
  }

  Future<void> _dispenseChange(int change) async {
    final values = coinDispenser.coinValues.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));

    while (change > 0) {
      final match = values.firstWhere(
          (coin) => change >= coin && availableCoins[coin]! > 0,
          orElse: () => -1);

      if (match < 0) break;

      await coinDispenser.dispenseCoin(match);
      await _updateAvailableCoins(match, -1);

      change -= match;
    }
  }

  Future<void> _updateAvailableCoins(int coin, int changeAmount) async {
    // Typically accepts larger coins than it needs for change
    // Ignore coins which are not supported by the dispenser
    if (!availableCoins.containsKey(coin)) return;

    availableCoins[coin] = availableCoins[coin]! + changeAmount;
    await saveFile.writeAsString(
      jsonEncode(
        availableCoins.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }
}
