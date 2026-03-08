import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/style_reference.dart';
import '../../utils/image_utils.dart';
import '../../widgets/style_dna_detail_view.dart';

class StyleDetailScreen extends StatelessWidget {
  final StyleReference style;

  const StyleDetailScreen({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveSourceImageUrl(style.sourceImagePath);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: Text(style.styleTag, style: AppTypography.headingMd),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(
                  flex: 45,
                  child: _buildImage(imageUrl),
                ),
                Expanded(
                  flex: 55,
                  child: StyleDnaDetailView(profile: style.profile),
                ),
              ],
            )
          : Column(
              children: [
                SizedBox(
                  height: 280,
                  child: _buildImage(imageUrl),
                ),
                Expanded(
                  child: StyleDnaDetailView(profile: style.profile),
                ),
              ],
            ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.bgElevated,
        child: const Center(
          child: Icon(Icons.image, size: 64, color: AppColors.textMuted),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.bgElevated),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.bgElevated,
        child: const Icon(Icons.broken_image,
            size: 48, color: AppColors.textMuted),
      ),
    );
  }
}
