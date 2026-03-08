import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class DnaHelixLoader extends StatefulWidget {
  final double size;
  final String? message;

  const DnaHelixLoader({super.key, this.size = 80, this.message});

  @override
  State<DnaHelixLoader> createState() => _DnaHelixLoaderState();
}

class _DnaHelixLoaderState extends State<DnaHelixLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _HelixPainter(
                  progress: _controller.value,
                  colors: StyleDNAColors.all,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 20),
          _PulsingText(text: widget.message!),
        ],
      ],
    );
  }
}

class _HelixPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _HelixPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final amplitude = size.width * 0.35;
    final rungs = 8;
    final phase = progress * 2 * pi;

    for (int i = 0; i < rungs; i++) {
      final t = i / rungs;
      final y = centerY - size.height * 0.4 + t * size.height * 0.8;
      final angle = t * 2 * pi + phase;

      final x1 = centerX + amplitude * sin(angle);
      final x2 = centerX + amplitude * sin(angle + pi);

      final depth1 = (cos(angle) + 1) / 2;
      final depth2 = (cos(angle + pi) + 1) / 2;

      final color = colors[i % colors.length];

      // Draw rung
      final rungPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);

      // Draw strand 1
      final paint1 = Paint()
        ..color = color.withValues(alpha: 0.4 + depth1 * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x1, y), 3 + depth1 * 2, paint1);

      // Draw strand 2
      final paint2 = Paint()
        ..color = color.withValues(alpha: 0.4 + depth2 * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x2, y), 3 + depth2 * 2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _HelixPainter old) =>
      old.progress != progress;
}

class _PulsingText extends StatefulWidget {
  final String text;
  const _PulsingText({required this.text});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + _controller.value * 0.5,
          child: Text(
            widget.text,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
