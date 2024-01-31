import 'payment.welltested_test.mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vendo/coin_selector.dart';
import 'package:vendo/payment_provider.dart';
import 'coin_selector.dart';

@GenerateMocks([CoinSelector])
void main() {
  group('PaymentProvider', () {
    test('returns correct payment when valid coins are provided', () async {
      final mockCoinSelector = MockCoinSelector();
      when(mockCoinSelector.coins)
          .thenAnswer((_) => Stream.fromIterable([1.0, 2.0, 3.0]));
      final paymentProvider = PaymentProvider(mockCoinSelector);
      expect(paymentProvider.payment(6.0), emitsInOrder([1.0, 3.0, 6.0]));
    });

    test('returns correct payment when no coins are provided', () async {
      final mockCoinSelector = MockCoinSelector();
      when(mockCoinSelector.coins).thenAnswer((_) => Stream.fromIterable([]));
      final paymentProvider = PaymentProvider(mockCoinSelector);
      expect(paymentProvider.payment(0.0), emitsDone);
    });

    test('returns correct payment when coins are provided in random order',
        () async {
      final mockCoinSelector = MockCoinSelector();
      when(mockCoinSelector.coins)
          .thenAnswer((_) => Stream.fromIterable([2.0, 1.0, 3.0]));
      final paymentProvider = PaymentProvider(mockCoinSelector);
      expect(paymentProvider.payment(6.0), emitsInOrder([2.0, 3.0, 6.0]));
    });

    test(
        'returns correct payment when price is less than the total coins provided',
        () async {
      final mockCoinSelector = MockCoinSelector();
      when(mockCoinSelector.coins)
          .thenAnswer((_) => Stream.fromIterable([1.0, 2.0, 3.0, 4.0]));
      final paymentProvider = PaymentProvider(mockCoinSelector);
      expect(paymentProvider.payment(5.0), emitsInOrder([1.0, 3.0, 6.0, 10.0]));
    });

    test(
        'returns correct payment when price is more than the total coins provided',
        () async {
      final mockCoinSelector = MockCoinSelector();
      when(mockCoinSelector.coins)
          .thenAnswer((_) => Stream.fromIterable([1.0, 2.0]));
      final paymentProvider = PaymentProvider(mockCoinSelector);
      expect(paymentProvider.payment(10.0), emitsInOrder([1.0, 3.0]));
    });
  });
}
