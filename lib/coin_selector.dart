import 'package:flutter_gpiod/flutter_gpiod.dart';

class CoinSelector {
  const CoinSelector({
    required this.pulsePin,
    required this.pulseBias,
    required this.pulseActiveState,
    required this.pulseEndEdge,
  });

  final GpioLine pulsePin;
  final Bias pulseBias;
  final ActiveState pulseActiveState;
  final SignalEdge pulseEndEdge;

  void activate() {
    pulsePin.requestInput(
      consumer: "COIN_SELECTOR",
      bias: pulseBias,
      activeState: pulseActiveState,
      triggers: {pulseEndEdge},
    );
  }

  void deactivate() {
    pulsePin.release();
  }

  Stream<SignalEvent> get events => pulsePin.onEvent.where(
        (event) => event.edge == pulseEndEdge,
      );

  @override
  String toString() {
    return 'CoinSelector{#'
        'pulsePin: ${pulsePin.info.name}, '
        'pulseBias: $pulseBias, '
        'pulseActiveState: $pulseActiveState, '
        'pulseEndEdge: $pulseEndEdge'
        '}';
  }
}
