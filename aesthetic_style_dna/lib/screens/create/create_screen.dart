import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../providers/style_library_provider.dart';
import '../../providers/selected_styles_provider.dart';
import '../../providers/create_provider.dart';
import '../../widgets/compact_style_card.dart';
import '../../widgets/selected_style_chips.dart';
import '../../widgets/dna_helix_loader.dart';
import '../../widgets/generation_result_view.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _promptController = TextEditingController();
  final _widthController = TextEditingController(text: '1024');
  final _heightController = TextEditingController(text: '1024');
  final _searchController = TextEditingController();
  bool _showAdvanced = false;
  File? _referenceImage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _generate() {
    final selectedIds = ref.read(selectedStylesProvider);
    if (selectedIds.isEmpty) return;

    final library = ref.read(styleLibraryProvider).valueOrNull ?? [];
    final validIds = library.map((s) => s.id).toSet();
    final staleIds =
        selectedIds.where((id) => !validIds.contains(id)).toSet();
    if (staleIds.isNotEmpty) {
      for (final id in staleIds) {
        ref.read(selectedStylesProvider.notifier).remove(id);
      }
      ref.read(styleLibraryProvider.notifier).refresh();
      return;
    }

    ref.read(createStateProvider.notifier).generate(
          styleIds: selectedIds.toList(),
          prompt: _promptController.text.isNotEmpty
              ? _promptController.text
              : null,
          width: int.tryParse(_widthController.text) ?? 1024,
          height: int.tryParse(_heightController.text) ?? 1024,
          referenceImage: _referenceImage,
        );
  }

  Future<void> _pickReferenceImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _referenceImage = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createStateProvider);
    final libraryAsync = ref.watch(styleLibraryProvider);
    final selectedIds = ref.watch(selectedStylesProvider);

    return Row(
      children: [
        // LEFT PANEL — Style Selector
        SizedBox(
          width: 280,
          child: _buildStylePanel(libraryAsync, selectedIds),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // CENTER PANEL — Prompt & Settings
        Expanded(
          child: _buildPromptPanel(selectedIds, createState),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // RIGHT PANEL — Result
        Expanded(
          child: _buildResultPanel(createState),
        ),
      ],
    );
  }

  Widget _buildStylePanel(
      AsyncValue libraryAsync, Set<String> selectedIds) {
    return Container(
      color: AppColors.bgBase,
      child: Column(
        children: [
          // Header + search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'STYLES',
                      style: AppTypography.labelMd.copyWith(
                        letterSpacing: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (selectedIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimaryMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedIds.length}/3',
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
          // Style list
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
                    child: Text('No matches',
                        style: AppTypography.bodySm),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final style = filtered[index];
                    return CompactStyleCard(
                      style: style,
                      isSelected: selectedIds.contains(style.id),
                      onTap: () => ref
                          .read(selectedStylesProvider.notifier)
                          .toggle(style.id),
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

  Widget _buildPromptPanel(
      Set<String> selectedIds, AsyncValue createState) {
    final libraryAsync = ref.watch(styleLibraryProvider);
    final isLoading = createState is AsyncLoading;

    return Container(
      color: AppColors.bgDeepest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create with Style', style: AppTypography.displayMd)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Select styles and describe your image',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: 20),

            // Selected style chips
            libraryAsync.when(
              data: (styles) {
                final selected = styles
                    .where((s) => selectedIds.contains(s.id))
                    .toList();
                return SelectedStyleChips(
                  selectedStyles: selected,
                  onRemove: (id) =>
                      ref.read(selectedStylesProvider.notifier).remove(id),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            if (selectedIds.isNotEmpty) const SizedBox(height: 20),

            // Prompt section
            Text(
              'DESCRIBE YOUR IMAGE',
              style: AppTypography.labelMd.copyWith(
                letterSpacing: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 4,
              maxLength: 500,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:
                    'A serene lake at dawn with mountains reflecting in still water...',
                counterStyle: AppTypography.bodySm,
              ),
            ),

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
            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Width',
                        labelStyle:
                            TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        labelStyle:
                            TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickReferenceImage,
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18),
                label: Text(_referenceImage != null
                    ? _referenceImage!.path.split('/').last
                    : 'Add reference image'),
              ),
            ],

            const SizedBox(height: 32),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    selectedIds.isNotEmpty && !isLoading ? _generate : null,
                icon: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  isLoading ? 'Generating...' : 'Generate Image',
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
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel(AsyncValue createState) {
    return Container(
      color: AppColors.bgBase,
      child: createState.when(
        data: (response) {
          if (response == null) {
            return _buildEmptyState();
          }
          return GenerationResultView(
            key: ValueKey(response.imageUrl),
            response: response,
          );
        },
        loading: () => Center(
          child: const DnaHelixLoader(
            size: 80,
            message: 'Generating your image...',
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
        error: (error, _) => _buildErrorState(error),
      ),
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
              border: Border.all(
                color: AppColors.borderSubtle,
                style: BorderStyle.solid,
              ),
              color: AppColors.bgSurface,
            ),
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your generated image\nwill appear here',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select styles and click Generate',
            style: AppTypography.bodySm,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 600.ms),
    );
  }

  Widget _buildErrorState(Object error) {
    String message = error.toString();
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
            Text('Generation Failed', style: AppTypography.headingLg),
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
                  ref.read(createStateProvider.notifier).reset(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
