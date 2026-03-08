import 'package:flutter/material.dart';
import '../config/theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 16,
    this.borderColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor ??
              (_hovering && isInteractive
                  ? AppColors.borderDefault
                  : AppColors.borderSubtle),
        ),
        boxShadow: _hovering && isInteractive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (isInteractive) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(onTap: widget.onTap, child: card),
      );
    }
    return card;
  }
}
