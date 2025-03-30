abstract class CoinDispenser {
  Future<void> dispense(int coin);
  List<int> get coinValues;
}
