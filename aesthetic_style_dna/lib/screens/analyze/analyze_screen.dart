import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/analyze_provider.dart';
import '../../providers/style_library_provider.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/dna_helix_loader.dart';
import '../../widgets/style_dna_card.dart';
import 'analyze_result_screen.dart';

class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _customTagController = TextEditingController();
  File? _droppedFile;

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _onFileDropped(File file) {
    setState(() => _droppedFile = file);
    final customTag = _customTagController.text.trim();
    ref.read(analyzeStateProvider.notifier).analyze(
          file,
          customTag: customTag.isNotEmpty ? customTag : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final analyzeState = ref.watch(analyzeStateProvider);
    final libraryAsync = ref.watch(styleLibraryProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return analyzeState.when(
      data: (response) {
        if (response != null && isWide) {
          // Wide: side-by-side — drop zone left, result right
          return Row(
            children: [
              Expanded(
                flex: 40,
                child: _buildDropZoneView(libraryAsync),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.borderSubtle,
              ),
              Expanded(
                flex: 60,
                child: AnalyzeResultScreen(
                  response: response,
                  onAnalyzeAnother: () {
                    ref.read(analyzeStateProvider.notifier).reset();
                  },
                ),
              ),
            ],
          );
        }
        if (response != null) {
          // Narrow: full replacement
          return AnalyzeResultScreen(
            response: response,
            onAnalyzeAnother: () {
              ref.read(analyzeStateProvider.notifier).reset();
            },
          );
        }
        return _buildDropZoneView(libraryAsync);
      },
      loading: () => _buildLoadingView(),
      error: (error, _) => _buildErrorView(error, libraryAsync),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show blurred thumbnail of dropped image if available
          if (_droppedFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.file(
                  _droppedFile!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const DnaHelixLoader(
            size: 80,
            message: 'Extracting Style DNA...',
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }

  Widget _buildDropZoneView(AsyncValue libraryAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                'Extract Style DNA',
                style: AppTypography.displayMd,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Upload an image to analyze its aesthetic properties',
                style: AppTypography.bodyMd,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 32),
              DropZone(onFileDropped: _onFileDropped)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.05,
                    delay: 200.ms,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 16),
              // Custom tag input
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _customTagController,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Custom style tag (optional)',
                    prefixIcon: const Icon(Icons.label_outline,
                        color: AppColors.textTertiary, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 40),
              // Recent styles
              _buildRecentStyles(libraryAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentStyles(AsyncValue libraryAsync) {
    return libraryAsync.when(
      data: (styles) {
        if (styles.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT EXTRACTIONS',
              style: AppTypography.labelMd.copyWith(
                letterSpacing: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: styles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 240,
                    child: StyleDnaCard(
                      style: styles[index],
                      onDelete: () {
                        ref
                            .read(styleLibraryProvider.notifier)
                            .deleteStyle(styles[index].id);
                      },
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: index * 60),
                          duration: 400.ms,
                        )
                        .slideX(
                          begin: 0.1,
                          delay: Duration(milliseconds: index * 60),
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildErrorView(Object error, AsyncValue libraryAsync) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.accentSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Analysis Failed',
                      style: AppTypography.headingLg,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(analyzeStateProvider.notifier).reset();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildRecentStyles(libraryAsync),
            ],
          ),
        ),
      ),
    );
  }
}
