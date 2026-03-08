import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/style_library_provider.dart';
import '../widgets/style_dna_card.dart';
import 'analyze/analyze_screen.dart';
import 'create/create_screen.dart';
import 'transfer/transfer_screen.dart';
import 'video/video_transfer_screen.dart';
import 'library/style_detail_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(activeTabProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgDeepest,
      endDrawer: _LibraryDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgBase,
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Logo
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.dnaRainbow.createShader(bounds),
                    child: Text(
                      'Style DNA',
                      style: AppTypography.displayMd.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Segmented control
                  _SegmentedControl(
                    selectedIndex: currentIndex,
                    onChanged: (i) =>
                        ref.read(activeTabProvider.notifier).state = i,
                  ),
                  const Spacer(),
                  // Library button
                  _HoverIconButton(
                    icon: Icons.collections_bookmark_outlined,
                    tooltip: 'Style Library',
                    onPressed: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: currentIndex,
        children: const [
          AnalyzeScreen(key: ValueKey('analyze')),
          CreateScreen(key: ValueKey('create')),
          TransferScreen(key: ValueKey('transfer')),
          VideoTransferScreen(key: ValueKey('video')),
        ],
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovering ? AppColors.bgElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hovering ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SegmentButton(
            index: 0,
            icon: Icons.analytics_outlined,
            label: 'Analyze',
            isActive: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _SegmentButton(
            index: 1,
            icon: Icons.auto_awesome_outlined,
            label: 'Create',
            isActive: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          _SegmentButton(
            index: 2,
            icon: Icons.style_outlined,
            label: 'Transfer',
            isActive: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
          _SegmentButton(
            index: 3,
            icon: Icons.videocam_outlined,
            label: 'Video',
            isActive: selectedIndex == 3,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.accentPrimary
                : _hovering
                    ? AppColors.bgOverlay
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.labelLg.copyWith(
                  color: widget.isActive
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(styleLibraryProvider);

    return Drawer(
      backgroundColor: AppColors.bgBase,
      width: 340,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Text('Style Library', style: AppTypography.headingLg),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: libraryAsync.when(
              data: (styles) {
                if (styles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No styles yet',
                            style: AppTypography.bodyMd),
                        const SizedBox(height: 4),
                        Text('Analyze an image to get started',
                            style: AppTypography.bodySm),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: styles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 300,
                      child: StyleDnaCard(
                        style: styles[index],
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StyleDetailScreen(
                                style: styles[index],
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          ref
                              .read(styleLibraryProvider.notifier)
                              .deleteStyle(styles[index].id);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentPrimary,
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('Could not load styles',
                        style: AppTypography.bodyMd),
                    const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
