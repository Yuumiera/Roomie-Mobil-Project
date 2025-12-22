import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  const PremiumBadge({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: 'Premium Member',
        child: Icon(
          Icons.verified,
          color: Colors.amber,
          size: size,
        ),
      ),
    );
  }
}
