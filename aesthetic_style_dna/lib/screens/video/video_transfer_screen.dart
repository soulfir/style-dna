import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/style_library_provider.dart';
import '../../providers/video_transfer_provider.dart';
import '../../widgets/compact_style_card.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/dna_helix_loader.dart';
import '../../widgets/video_progress_view.dart';
import '../../widgets/video_result_view.dart';

class VideoTransferScreen extends ConsumerStatefulWidget {
  const VideoTransferScreen({super.key});

  @override
  ConsumerState<VideoTransferScreen> createState() =>
      _VideoTransferScreenState();
}

class _VideoTransferScreenState extends ConsumerState<VideoTransferScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStyleId;
  File? _selectedVideo;
  bool _showAdvanced = false;

  bool _fastMode = false;
  // Standard settings
  int _sampleRate = 4;
  int _maxFrames = 120;
  bool _temporalSmoothing = true;
  // Fast settings
  int _numKeyframes = 6;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedVideo == null || _selectedStyleId == null) return;

    final library = ref.read(styleLibraryProvider).valueOrNull ?? [];
    final validIds = library.map((s) => s.id).toSet();
    if (!validIds.contains(_selectedStyleId)) {
      setState(() => _selectedStyleId = null);
      ref.read(styleLibraryProvider.notifier).refresh();
      return;
    }

    // Client-side file size check (100MB)
    final fileSize = _selectedVideo!.lengthSync();
    if (fileSize > 100 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video file must be under 100MB'),
          backgroundColor: AppColors.accentSecondary,
        ),
      );
      return;
    }

    if (_fastMode) {
      ref.read(videoTransferProvider.notifier).submitFastJob(
            video: _selectedVideo!,
            styleId: _selectedStyleId!,
            numKeyframes: _numKeyframes,
          );
    } else {
      ref.read(videoTransferProvider.notifier).submitJob(
            video: _selectedVideo!,
            styleId: _selectedStyleId!,
            sampleRate: _sampleRate,
            maxFrames: _maxFrames,
            temporalSmoothing: _temporalSmoothing,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoTransferProvider);
    final libraryAsync = ref.watch(styleLibraryProvider);

    return Row(
      children: [
        // LEFT — Style Picker
        SizedBox(
          width: 280,
          child: _buildStylePanel(libraryAsync),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // CENTER — Video Upload
        Expanded(
          child: _buildVideoPanel(videoState),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // RIGHT — Result
        Expanded(
          child: _buildResultPanel(videoState),
        ),
      ],
    );
  }

  Widget _buildStylePanel(AsyncValue libraryAsync) {
    return Container(
      color: AppColors.bgBase,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PICK STYLE',
                      style: AppTypography.labelMd.copyWith(
                        letterSpacing: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedStyleId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimaryMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '1 selected',
                          style: AppTypography.tag.copyWith(
                            color: AppColors.accentPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search styles...',
                      hintStyle: AppTypography.bodySm.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: AppColors.textTertiary),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      filled: true,
                      fillColor: AppColors.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: libraryAsync.when(
              data: (styles) {
                final filtered = _searchQuery.isEmpty
                    ? styles
                    : styles
                        .where((s) => s.styleTag
                            .toLowerCase()
                            .contains(_searchQuery))
                        .toList();

                if (styles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style_outlined,
                              size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No styles yet',
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.textTertiary)),
                          const SizedBox(height: 4),
                          Text('Analyze an image first',
                              style: AppTypography.bodySm,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child:
                        Text('No matches', style: AppTypography.bodySm),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final style = filtered[index];
                    return CompactStyleCard(
                      style: style,
                      isSelected: _selectedStyleId == style.id,
                      onTap: () {
                        setState(() {
                          if (_selectedStyleId == style.id) {
                            _selectedStyleId = null;
                          } else {
                            _selectedStyleId = style.id;
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentPrimary,
                  strokeWidth: 2,
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 32, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Failed to load',
                          style: AppTypography.bodySm),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(styleLibraryProvider.notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPanel(VideoTransferState videoState) {
    final isBusy = videoState.phase == VideoTransferPhase.uploading ||
        videoState.phase == VideoTransferPhase.processing;
    final canSubmit =
        _selectedVideo != null && _selectedStyleId != null && !isBusy;

    return Container(
      color: AppColors.bgDeepest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video Style Transfer', style: AppTypography.displayMd)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Apply a style to your video',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: 16),

            // Mode toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _fastMode = false),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_fastMode
                                ? AppColors.accentPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text(
                              'Standard',
                              style: AppTypography.labelMd.copyWith(
                                color: !_fastMode
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _fastMode = true),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _fastMode
                                ? AppColors.accentPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt,
                                    size: 14,
                                    color: _fastMode
                                        ? Colors.white
                                        : AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Fast',
                                  style: AppTypography.labelMd.copyWith(
                                    color: _fastMode
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fastMode
                  ? 'Optical flow mode — transfers keyframes only, 3-5x faster'
                  : 'Full frame-by-frame style transfer',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Video preview or drop zone
            if (_selectedVideo != null) ...[
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam,
                              size: 48, color: AppColors.accentPrimary),
                          const SizedBox(height: 12),
                          Text(
                            _selectedVideo!.path.split('/').last,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(
                                _selectedVideo!.lengthSync()),
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedVideo = null),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Colors.black.withValues(alpha: 0.6),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _selectedVideo = null),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change video'),
              ),
            ] else ...[
              DropZone(
                fileType: FileType.custom,
                allowedExtensions: const [
                  'mp4',
                  'mov',
                  'webm',
                  'avi',
                  'mkv'
                ],
                dropLabel: 'Drop a video or click to browse',
                formatHint:
                    'MP4, MOV, WEBM, AVI, MKV \u2014 max 60s, 100MB',
                icon: Icons.videocam_outlined,
                selectedIcon: Icons.videocam,
                onFileDropped: (file) {
                  setState(() => _selectedVideo = file);
                },
              ),
            ],

            const SizedBox(height: 16),

            // Advanced settings
            GestureDetector(
              onTap: () =>
                  setState(() => _showAdvanced = !_showAdvanced),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Icon(
                      _showAdvanced
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Advanced Settings',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showAdvanced && !_fastMode) ...[
              const SizedBox(height: 16),

              // Sample Rate
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sample Rate',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Every ${_sampleRate}${_sampleRate == 1 ? 'st' : _sampleRate == 2 ? 'nd' : _sampleRate == 3 ? 'rd' : 'th'} frame',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
              Slider(
                value: _sampleRate.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: AppColors.accentPrimary,
                inactiveColor: AppColors.bgElevated,
                onChanged: (v) =>
                    setState(() => _sampleRate = v.round()),
              ),

              const SizedBox(height: 8),

              // Max Frames
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Max Frames',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '$_maxFrames',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
              Slider(
                value: _maxFrames.toDouble(),
                min: 10,
                max: 500,
                divisions: 49,
                activeColor: AppColors.accentPrimary,
                inactiveColor: AppColors.bgElevated,
                onChanged: (v) =>
                    setState(() => _maxFrames = v.round()),
              ),

              const SizedBox(height: 8),

              // Temporal Smoothing
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temporal Smoothing',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Reduces flicker between frames',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _temporalSmoothing,
                    activeColor: AppColors.accentPrimary,
                    onChanged: (v) =>
                        setState(() => _temporalSmoothing = v),
                  ),
                ],
              ),
            ],
            if (_showAdvanced && _fastMode) ...[
              const SizedBox(height: 16),

              // Keyframes
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Keyframes',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '$_numKeyframes keyframes',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
              Slider(
                value: _numKeyframes.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                activeColor: AppColors.accentPrimary,
                inactiveColor: AppColors.bgElevated,
                onChanged: (v) =>
                    setState(() => _numKeyframes = v.round()),
              ),
            ],

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : const Icon(Icons.videocam, size: 18),
                label: Text(
                  isBusy
                      ? 'Processing...'
                      : _fastMode
                          ? 'Fast Transfer'
                          : 'Transfer Style',
                  style: AppTypography.labelLg.copyWith(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accentPrimary,
                  disabledBackgroundColor:
                      AppColors.accentPrimary.withValues(alpha: 0.4),
                  disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Status hints
            if (_selectedVideo == null ||
                _selectedStyleId == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _selectedStyleId != null
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: _selectedStyleId != null
                        ? AppColors.accentSuccess
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Select a style from the left panel',
                    style: AppTypography.bodySm.copyWith(
                      color: _selectedStyleId != null
                          ? AppColors.accentSuccess
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _selectedVideo != null
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: _selectedVideo != null
                        ? AppColors.accentSuccess
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Upload a video above',
                    style: AppTypography.bodySm.copyWith(
                      color: _selectedVideo != null
                          ? AppColors.accentSuccess
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel(VideoTransferState videoState) {
    return Container(
      color: AppColors.bgBase,
      child: switch (videoState.phase) {
        VideoTransferPhase.idle => _buildEmptyState(),
        VideoTransferPhase.uploading => Center(
            child: const DnaHelixLoader(
              size: 80,
              message: 'Uploading video...',
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        VideoTransferPhase.processing => videoState.latestStatus != null
            ? VideoProgressView(
                status: videoState.latestStatus!,
                jobResponse: videoState.jobResponse,
              )
            : Center(
                child: const DnaHelixLoader(
                  size: 80,
                  message: 'Starting job...',
                )
                    .animate()
                    .fadeIn(duration: 400.ms),
              ),
        VideoTransferPhase.completed =>
          videoState.latestStatus?.resultUrl != null
              ? VideoResultView(
                  key: ValueKey(videoState.latestStatus!.resultUrl),
                  videoUrl: ApiConfig.outputUrl(
                      videoState.latestStatus!.resultUrl!),
                )
              : _buildEmptyState(),
        VideoTransferPhase.failed =>
          _buildErrorState(videoState.error ?? 'Unknown error'),
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
              color: AppColors.bgSurface,
            ),
            child: Icon(
              Icons.videocam_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your styled video\nwill appear here',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a style and upload a video',
            style: AppTypography.bodySm,
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildErrorState(String error) {
    String message = error;
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.accentSecondary),
            const SizedBox(height: 16),
            Text('Transfer Failed', style: AppTypography.headingLg),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.accentSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(videoTransferProvider.notifier).reset(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
