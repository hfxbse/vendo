import 'package:flutter/material.dart';

class PaymentProcessBar extends StatelessWidget {
  const PaymentProcessBar(this.payment, this.price, {super.key});

  final Stream<int> payment;
  final int price;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: payment,
      builder: (context, snapshot) {
        final payedAmount = snapshot.hasData ? snapshot.data! : 0;
        final restAmount = (price - payedAmount).clamp(0, price);

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 150),
              tween: Tween(begin: 0, end: payedAmount.toDouble()),
              curve: Curves.easeInOut,
              builder: (_, num payedAmount, __) => LinearProgressIndicator(
                color: Colors.green,
                backgroundColor: Colors.transparent,
                value: payedAmount / price,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.black,
                      width: 3,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 35,
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(Icons.cancel_outlined),
                      ),
                      Text(
                        "Offener Betrag: ${(restAmount.toDouble() / 100).toStringAsFixed(2)} €",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
