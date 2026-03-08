import 'package:flutter/material.dart';
import '../config/theme.dart';

class MoodChip extends StatefulWidget {
  final String label;
  final Color? color;

  const MoodChip({super.key, required this.label, this.color});

  @override
  State<MoodChip> createState() => _MoodChipState();
}

class _MoodChipState extends State<MoodChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final chipColor = widget.color ?? AppColors.accentPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: chipColor.withValues(alpha: _hovering ? 0.2 : 0.12),
          border: Border.all(
            color: chipColor.withValues(alpha: _hovering ? 0.4 : 0.25),
          ),
        ),
        child: Text(
          widget.label,
          style: AppTypography.tag.copyWith(color: chipColor, fontSize: 11),
        ),
      ),
    );
  }
}
