import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class ImagePreviewOverlay extends StatelessWidget {
  final String imageUrl;
  final String? caption;

  const ImagePreviewOverlay({
    super.key,
    required this.imageUrl,
    this.caption,
  });

  static void show(BuildContext context,
      {required String imageUrl, String? caption}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) =>
            ImagePreviewOverlay(imageUrl: imageUrl, caption: caption),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppColors.bgDeepest.withValues(alpha: 0.85),
              ),
            ),
            // Image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: AppColors.textMuted,
                    size: 64,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 48,
              right: 24,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgSurface.withValues(alpha: 0.6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Caption
            if (caption != null)
              Positioned(
                bottom: 48,
                left: 48,
                right: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        caption!,
                        style: AppTypography.bodyMd,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
