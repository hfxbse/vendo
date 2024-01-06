class PaymentProvider {
  Stream<double> payment() {
    return Stream.fromFutures([
      Future.delayed(const Duration(seconds: 1), () => 0.2),
      Future.delayed(const Duration(seconds: 3), () => 0.3),
      Future.delayed(const Duration(seconds: 4), () => 0.4),
      Future.delayed(const Duration(seconds: 6), () => 0.6)
    ]);
  }
}
