import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/style_reference.dart';

class SelectedStyleChips extends StatelessWidget {
  final List<StyleReference> selectedStyles;
  final void Function(String id) onRemove;

  const SelectedStyleChips({
    super.key,
    required this.selectedStyles,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedStyles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selectedStyles.map((style) {
        return Container(
          padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.accentPrimaryMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                style.styleTag,
                style: AppTypography.tag.copyWith(
                  color: AppColors.accentPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onRemove(style.id),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
