import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/create_response.dart';
import '../utils/download_utils.dart';
import '../utils/image_utils.dart';
import 'image_preview_overlay.dart';

class GenerationResultView extends StatefulWidget {
  final CreateResponse response;
  const GenerationResultView({
    super.key,
    required this.response,
  });

  @override
  State<GenerationResultView> createState() => _GenerationResultViewState();
}

class _GenerationResultViewState extends State<GenerationResultView>
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
  void didUpdateWidget(GenerationResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response.imageUrl != widget.response.imageUrl) {
      _blurController.reset();
      _blurController.forward();
    }
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result', style: AppTypography.headingLg)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Image with blur reveal
          GestureDetector(
            onTap: () => ImagePreviewOverlay.show(
              context,
              imageUrl: imageUrl,
              caption: null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _blurController,
                    builder: (context, child) {
                      final blur = 40.0 * (1 - _blurController.value);
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
                        height: 300,
                        color: AppColors.bgElevated,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: AppColors.textMuted, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
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
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.download,
                                  color: Colors.white70, size: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fullscreen,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text('Preview',
                                  style: AppTypography.bodySm
                                      .copyWith(color: Colors.white70, fontSize: 10)),
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


        ],
      ),
    );
  }
}
