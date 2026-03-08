import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/style_reference.dart';
import 'style_dna_card.dart';
import 'shimmer_loading.dart';

class StyleSelectorGrid extends StatelessWidget {
  final List<StyleReference> styles;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;
  final bool isLoading;

  const StyleSelectorGrid({
    super.key,
    required this.styles,
    required this.selectedIds,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }

    if (styles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No styles yet',
              style: AppTypography.headingMd.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze an image first to build your style library',
              style: AppTypography.bodyMd,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: styles.length,
      itemBuilder: (context, index) {
        final style = styles[index];
        return StyleDnaCard(
          style: style,
          isSelected: selectedIds.contains(style.id),
          selectable: true,
          onTap: () => onToggle(style.id),
        )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: 400.ms,
            )
            .slideY(
              begin: 0.1,
              delay: Duration(milliseconds: index * 50),
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}
