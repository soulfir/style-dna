import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../providers/style_library_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../widgets/compact_style_card.dart';
import '../../widgets/drop_zone.dart';
import '../../widgets/dna_helix_loader.dart';
import '../../widgets/generation_result_view.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _searchController = TextEditingController();
  final _widthController = TextEditingController(text: '1024');
  final _heightController = TextEditingController(text: '1024');
  String _searchQuery = '';
  String? _selectedStyleId;
  File? _selectedImage;
  bool _showAdvanced = false;

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
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _transfer() {
    if (_selectedImage == null || _selectedStyleId == null) return;

    // Validate style still exists
    final library = ref.read(styleLibraryProvider).valueOrNull ?? [];
    final validIds = library.map((s) => s.id).toSet();
    if (!validIds.contains(_selectedStyleId)) {
      setState(() => _selectedStyleId = null);
      ref.read(styleLibraryProvider.notifier).refresh();
      return;
    }

    ref.read(transferStateProvider.notifier).transfer(
          image: _selectedImage!,
          styleId: _selectedStyleId!,
          width: int.tryParse(_widthController.text) ?? 1024,
          height: int.tryParse(_heightController.text) ?? 1024,
        );
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferStateProvider);
    final libraryAsync = ref.watch(styleLibraryProvider);

    return Row(
      children: [
        // LEFT — Style Picker (single select)
        SizedBox(
          width: 280,
          child: _buildStylePanel(libraryAsync),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // CENTER — Image Upload
        Expanded(
          child: _buildImagePanel(transferState),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.borderSubtle,
        ),

        // RIGHT — Result
        Expanded(
          child: _buildResultPanel(transferState),
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

  Widget _buildImagePanel(AsyncValue transferState) {
    final isLoading = transferState is AsyncLoading;
    final canTransfer =
        _selectedImage != null && _selectedStyleId != null && !isLoading;

    return Container(
      color: AppColors.bgDeepest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Style Transfer', style: AppTypography.displayMd)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Apply a style to your image',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: 24),

            // Image preview or drop zone
            if (_selectedImage != null) ...[
              // Show selected image preview
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedImage!.path.split('/').last,
                        style: AppTypography.bodySm
                            .copyWith(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change image'),
              ),
            ] else ...[
              DropZone(
                onFileDropped: (file) {
                  setState(() => _selectedImage = file);
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
            ],

            const SizedBox(height: 32),

            // Transfer button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canTransfer ? _transfer : null,
                icon: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : const Icon(Icons.style, size: 18),
                label: Text(
                  isLoading ? 'Transferring...' : 'Transfer Style',
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
            if (_selectedImage == null || _selectedStyleId == null) ...[
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
                    _selectedImage != null
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 14,
                    color: _selectedImage != null
                        ? AppColors.accentSuccess
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Upload an image above',
                    style: AppTypography.bodySm.copyWith(
                      color: _selectedImage != null
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

  Widget _buildResultPanel(AsyncValue transferState) {
    return Container(
      color: AppColors.bgBase,
      child: transferState.when(
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
            message: 'Applying style transfer...',
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
              border: Border.all(color: AppColors.borderSubtle),
              color: AppColors.bgSurface,
            ),
            child: Icon(
              Icons.style_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your styled image\nwill appear here',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a style and upload an image',
            style: AppTypography.bodySm,
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
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
                  ref.read(transferStateProvider.notifier).reset(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
