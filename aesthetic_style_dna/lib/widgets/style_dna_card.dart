import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/style_reference.dart';
import '../utils/image_utils.dart';
import 'color_palette_strip.dart';
import 'mood_chip.dart';
import 'animated_gradient_border.dart';

class StyleDnaCard extends StatefulWidget {
  final StyleReference style;
  final bool isSelected;
  final bool selectable;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const StyleDnaCard({
    super.key,
    required this.style,
    this.isSelected = false,
    this.selectable = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<StyleDnaCard> createState() => _StyleDnaCardState();
}

class _StyleDnaCardState extends State<StyleDnaCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveSourceImageUrl(widget.style.sourceImagePath);
    final profile = widget.style.profile;

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_hovering ? 1.02 : 1.0, _hovering ? 1.02 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimaryMuted
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accentPrimary
                  : _hovering
                      ? AppColors.borderDefault
                      : AppColors.borderSubtle,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.bgElevated,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.bgElevated,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.textMuted),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.bgElevated,
                          child: const Icon(Icons.image,
                              color: AppColors.textMuted, size: 40),
                        ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.bgSurface.withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Selection checkmark
                      if (widget.isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentPrimary,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      // Delete button
                      if (widget.onDelete != null && _hovering)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Content section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.style.styleTag,
                      style: AppTypography.tag.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ColorPaletteStrip(
                      colorNames: profile.colorGrading.dominantColors
                          .take(5)
                          .toList(),
                      circleSize: 16,
                      animate: false,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        MoodChip(
                          label: profile.atmosphere.mood,
                          color: StyleDNAColors.atmosphere,
                        ),
                        MoodChip(
                          label: profile.colorGrading.paletteType,
                          color: StyleDNAColors.colorGrading,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mini property bars
                    _MiniPropertyBars(profile: profile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isSelected) {
      card = AnimatedGradientBorder(
        borderRadius: 18,
        strokeWidth: 2,
        child: card,
      );
    }

    return card;
  }
}

class _MiniPropertyBars extends StatelessWidget {
  final dynamic profile;

  const _MiniPropertyBars({required this.profile});

  double _getLevel(String value, List<String> levels) {
    final idx =
        levels.indexWhere((l) => l.toLowerCase() == value.toLowerCase());
    if (idx < 0) return 0.5;
    return (idx + 1) / levels.length;
  }

  @override
  Widget build(BuildContext context) {
    final bars = <_BarData>[
      _BarData(
          'CLR',
          _getLevel(
              profile.colorGrading.saturation, ['low', 'medium', 'high', 'vivid']),
          StyleDNAColors.colorGrading),
      _BarData(
          'LGT',
          _getLevel(
              profile.lighting.contrastRatio, ['low', 'medium', 'high', 'extreme']),
          StyleDNAColors.lighting),
      _BarData(
          'TXT',
          _getLevel(
              profile.texture.grain, ['none', 'fine', 'medium', 'heavy']),
          StyleDNAColors.texture),
      _BarData(
          'CMP',
          _getLevel(
              profile.composition.depthLayers, ['flat', 'shallow', 'medium', 'deep']),
          StyleDNAColors.composition),
      _BarData(
          'CON',
          _getLevel(profile.contrast.dynamicRange,
              ['compressed', 'normal', 'wide', 'HDR']),
          StyleDNAColors.contrast),
      _BarData(
          'ATM',
          _getLevel(
              profile.texture.sharpness, ['soft', 'moderate', 'sharp', 'crisp']),
          StyleDNAColors.atmosphere),
    ];

    return Row(
      children: bars.map((bar) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Column(
              children: [
                Text(
                  bar.label,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: bar.color.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: AppColors.borderSubtle,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: bar.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: bar.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  _BarData(this.label, this.value, this.color);
}
