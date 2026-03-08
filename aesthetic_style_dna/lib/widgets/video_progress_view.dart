import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/video_job_status.dart';
import '../models/video_transfer_response.dart';
import 'dna_helix_loader.dart';

class VideoProgressView extends StatelessWidget {
  final VideoJobStatus status;
  final VideoTransferResponse? jobResponse;

  const VideoProgressView({
    super.key,
    required this.status,
    this.jobResponse,
  });

  static const _stages = [
    'extracting',
    'transferring',
    'interpolating',
    'assembling',
  ];

  static const _stageLabels = {
    'queued': 'Queued...',
    'extracting': 'Extracting frames...',
    'transferring': 'Applying style transfer...',
    'interpolating': 'Interpolating frames...',
    'assembling': 'Assembling video...',
  };

  @override
  Widget build(BuildContext context) {
    final currentStageIndex = _stages.indexOf(status.status);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DnaHelixLoader(size: 56)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms),
          const SizedBox(height: 32),

          Text(
            _stageLabels[status.status] ?? 'Processing...',
            style: AppTypography.headingMd,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // Pipeline stages
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_stages.length, (i) {
              final isActive = i == currentStageIndex;
              final isDone = i < currentStageIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.accentPrimary
                            : isActive
                                ? AppColors.accentPrimary
                                : AppColors.bgElevated,
                        border: Border.all(
                          color: isActive
                              ? AppColors.accentPrimary
                              : AppColors.borderDefault,
                          width: 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.accentPrimary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (i < _stages.length - 1) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 24,
                        height: 2,
                        color: isDone
                            ? AppColors.accentPrimary
                            : AppColors.borderSubtle,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _stages.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 74,
                  child: Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 9,
                      color: s == status.status
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: 300,
              child: Stack(
                children: [
                  Container(color: AppColors.bgElevated),
                  FractionallySizedBox(
                    widthFactor: status.progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.dnaRainbow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            '${status.processedFrames} / ${status.totalFrames} frames processed',
            style: AppTypography.bodySm,
          ),

          if (status.estimatedTimeRemaining != null) ...[
            const SizedBox(height: 4),
            Text(
              '~${status.estimatedTimeRemaining!.round()}s remaining',
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.textMuted),
            ),
          ],

          if (jobResponse != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${jobResponse!.videoInfo.width}×${jobResponse!.videoInfo.height} · '
                    '${jobResponse!.videoInfo.fps.round()} fps · '
                    '${jobResponse!.videoInfo.duration.toStringAsFixed(1)}s',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
