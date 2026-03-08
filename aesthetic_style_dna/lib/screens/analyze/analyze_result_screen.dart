import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/analyze_response.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/selected_styles_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/style_dna_detail_view.dart';

class AnalyzeResultScreen extends ConsumerWidget {
  final AnalyzeResponse response;
  final VoidCallback onAnalyzeAnother;

  const AnalyzeResultScreen({
    super.key,
    required this.response,
    required this.onAnalyzeAnother,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl =
        resolveSourceImageUrl(response.style.sourceImagePath);
    final isWide = MediaQuery.of(context).size.width > 900;

    if (isWide) {
      return Row(
        children: [
          // Left: Image
          Expanded(
            flex: 45,
            child: _buildImageSection(imageUrl),
          ),
          // Right: Detail
          Expanded(
            flex: 55,
            child: Column(
              children: [
                Expanded(
                  child: StyleDnaDetailView(
                    profile: response.style.profile,
                  ),
                ),
                _buildActions(ref),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: _buildImageSection(imageUrl),
        ),
        Expanded(
          child: StyleDnaDetailView(
            profile: response.style.profile,
          ),
        ),
        _buildActions(ref),
      ],
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Container(
      color: AppColors.bgBase,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.bgElevated),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.bgElevated,
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.textMuted, size: 48),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.bgBase.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Style tag overlay
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    response.style.styleTag,
                    style: AppTypography.tag.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.3, duration: 400.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAnalyzeAnother,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Analyze Another'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(selectedStylesProvider.notifier)
                    .setStyles({response.style.id});
                ref.read(activeTabProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Use in Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
