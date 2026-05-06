import 'package:flutter/material.dart';

class EdgeOverscrollBackground extends StatelessWidget {
  final Color topColor;
  final Color bottomColor;
  final Widget child;

  const EdgeOverscrollBackground({
    super.key,
    required this.topColor,
    required this.bottomColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: ColoredBox(color: topColor)),
            Expanded(child: ColoredBox(color: bottomColor)),
          ],
        ),
        child,
      ],
    );
  }
}
