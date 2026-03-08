import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/style_reference.dart';
import '../utils/image_utils.dart';

class CompactStyleCard extends StatefulWidget {
  final StyleReference style;
  final bool isSelected;
  final VoidCallback? onTap;

  const CompactStyleCard({
    super.key,
    required this.style,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<CompactStyleCard> createState() => _CompactStyleCardState();
}

class _CompactStyleCardState extends State<CompactStyleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveSourceImageUrl(widget.style.sourceImagePath);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimaryMuted
                : _hovering
                    ? AppColors.bgSurfaceHover
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isSelected
                    ? AppColors.accentPrimary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.bgElevated),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.bgElevated,
                            child: const Icon(Icons.image,
                                color: AppColors.textMuted, size: 20),
                          ),
                        )
                      : Container(
                          color: AppColors.bgElevated,
                          child: const Icon(Icons.image,
                              color: AppColors.textMuted, size: 20),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.style.styleTag,
                      style: AppTypography.tag.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.style.profile.atmosphere.mood,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Checkmark
              if (widget.isSelected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentPrimary,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
