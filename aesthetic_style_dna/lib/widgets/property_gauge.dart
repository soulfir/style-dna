import 'package:flutter/material.dart';
import '../config/theme.dart';

class PropertyGauge extends StatefulWidget {
  final String label;
  final String value;
  final List<String> levels;
  final Color color;

  const PropertyGauge({
    super.key,
    required this.label,
    required this.value,
    required this.levels,
    required this.color,
  });

  @override
  State<PropertyGauge> createState() => _PropertyGaugeState();
}

class _PropertyGaugeState extends State<PropertyGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.levels.indexWhere(
        (l) => l.toLowerCase() == widget.value.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label.toUpperCase(),
              style: AppTypography.labelMd.copyWith(
                color: widget.color,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.value,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Row(
              children: List.generate(widget.levels.length, (i) {
                final isActive = i <= activeIndex && activeIndex >= 0;
                final segmentProgress = isActive
                    ? (_animation.value * widget.levels.length - i)
                        .clamp(0.0, 1.0)
                    : 0.0;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: i < widget.levels.length - 1 ? 3 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive
                          ? widget.color
                              .withValues(alpha: 0.8 * segmentProgress)
                          : AppColors.borderSubtle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
