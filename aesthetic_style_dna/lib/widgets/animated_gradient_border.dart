import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final bool animate;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 2,
    this.animate = true,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            strokeWidth: widget.strokeWidth,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.all(widget.strokeWidth),
        child: widget.child,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(progress * 2 * pi),
        colors: const [
          AppColors.accentPrimary,
          Color(0xFFE5484D),
          Color(0xFFF5A623),
          Color(0xFF87CEAB),
          Color(0xFF5B9EE9),
          AppColors.accentPrimary,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.progress != progress;
}
