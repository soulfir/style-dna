import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/color_utils.dart';

class ColorPaletteStrip extends StatelessWidget {
  final List<String> colorNames;
  final double circleSize;
  final bool animate;

  const ColorPaletteStrip({
    super.key,
    required this.colorNames,
    this.circleSize = 20,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(colorNames.length, (i) {
        final color = colorFromName(colorNames[i]);
        Widget circle = Tooltip(
          message: colorNames[i],
          child: Container(
            width: circleSize,
            height: circleSize,
            margin: EdgeInsets.only(right: i < colorNames.length - 1 ? 6 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
        );

        if (animate) {
          circle = circle
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                delay: Duration(milliseconds: i * 60),
                duration: 400.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(delay: Duration(milliseconds: i * 60), duration: 200.ms);
        }

        return circle;
      }),
    );
  }
}
