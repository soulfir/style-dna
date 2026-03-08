import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/create_response.dart';
import '../../utils/download_utils.dart';
import '../../utils/image_utils.dart';
import '../../widgets/image_preview_overlay.dart';

class GenerationResultScreen extends StatefulWidget {
  final CreateResponse response;
  final VoidCallback onGenerateAnother;

  const GenerationResultScreen({
    super.key,
    required this.response,
    required this.onGenerateAnother,
  });

  @override
  State<GenerationResultScreen> createState() => _GenerationResultScreenState();
}

class _GenerationResultScreenState extends State<GenerationResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blurController;

  @override
  void initState() {
    super.initState();
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOutputImageUrl(widget.response.imageUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generated Image', style: AppTypography.displayMd)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // Image with blur reveal animation
              GestureDetector(
                onTap: () => ImagePreviewOverlay.show(
                  context,
                  imageUrl: imageUrl,
                  caption: null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _blurController,
                        builder: (context, child) {
                          final blur =
                              40.0 * (1 - _blurController.value);
                          return ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: blur,
                              sigmaY: blur,
                            ),
                            child: child,
                          );
                        },
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 400,
                            color: AppColors.bgElevated,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: AppColors.textMuted, size: 48),
                            ),
                          ),
                        ),
                      ),
                      // Tap hint + download
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => downloadFile(
                                url: imageUrl,
                                defaultFilename: 'style_dna_${DateTime.now().millisecondsSinceEpoch}.png',
                                context: context,
                              ),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.download,
                                      color: Colors.white70, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fullscreen,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text('Tap to preview',
                                      style: AppTypography.bodySm
                                          .copyWith(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 1500.ms, duration: 400.ms),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(1.02, 1.02),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onGenerateAnother,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Generate Another'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
