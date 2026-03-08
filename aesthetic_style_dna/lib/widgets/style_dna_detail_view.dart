import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/aesthetic_profile.dart';
import 'color_palette_strip.dart';
import 'mood_chip.dart';
import 'property_gauge.dart';
import 'glass_card.dart';

class StyleDnaDetailView extends StatelessWidget {
  final AestheticProfile profile;

  const StyleDnaDetailView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      // Style tag header
      Text(
        profile.styleTag,
        style: AppTypography.displayMd.copyWith(
          foreground: Paint()
            ..shader = AppGradients.dnaRainbow
                .createShader(const Rect.fromLTWH(0, 0, 300, 30)),
        ),
      ),
      const SizedBox(height: 24),

      // Color Grading
      _buildSection(
        'Color Grading',
        StyleDNAColors.colorGrading,
        Icons.palette_outlined,
        [
          ColorPaletteStrip(
            colorNames: profile.colorGrading.dominantColors,
            circleSize: 24,
          ),
          const SizedBox(height: 16),
          PropertyGauge(
            label: 'Saturation',
            value: profile.colorGrading.saturation,
            levels: const ['low', 'medium', 'high', 'vivid'],
            color: StyleDNAColors.colorGrading,
          ),
          const SizedBox(height: 12),
          _infoRow('Palette', profile.colorGrading.paletteType),
          _infoRow('Temperature', profile.colorGrading.colorTemperature),
        ],
      ),

      // Lighting
      _buildSection(
        'Lighting',
        StyleDNAColors.lighting,
        Icons.wb_sunny_outlined,
        [
          PropertyGauge(
            label: 'Quality',
            value: profile.lighting.quality,
            levels: const ['hard', 'soft', 'diffused', 'mixed'],
            color: StyleDNAColors.lighting,
          ),
          const SizedBox(height: 12),
          PropertyGauge(
            label: 'Contrast',
            value: profile.lighting.contrastRatio,
            levels: const ['low', 'medium', 'high', 'extreme'],
            color: StyleDNAColors.lighting,
          ),
          const SizedBox(height: 12),
          _infoRow('Direction', profile.lighting.direction),
          _infoRow('Mood', profile.lighting.mood),
        ],
      ),

      // Texture
      _buildSection(
        'Texture',
        StyleDNAColors.texture,
        Icons.texture_outlined,
        [
          PropertyGauge(
            label: 'Grain',
            value: profile.texture.grain,
            levels: const ['none', 'fine', 'medium', 'heavy'],
            color: StyleDNAColors.texture,
          ),
          const SizedBox(height: 12),
          PropertyGauge(
            label: 'Sharpness',
            value: profile.texture.sharpness,
            levels: const ['soft', 'moderate', 'sharp', 'crisp'],
            color: StyleDNAColors.texture,
          ),
          const SizedBox(height: 12),
          _infoRow('Surface', profile.texture.surfaceQuality),
        ],
      ),

      // Composition
      _buildSection(
        'Composition',
        StyleDNAColors.composition,
        Icons.grid_on_outlined,
        [
          PropertyGauge(
            label: 'Depth',
            value: profile.composition.depthLayers,
            levels: const ['flat', 'shallow', 'medium', 'deep'],
            color: StyleDNAColors.composition,
          ),
          const SizedBox(height: 12),
          _infoRow('Technique', profile.composition.technique),
          _infoRow('Framing', profile.composition.framing),
        ],
      ),

      // Contrast
      _buildSection(
        'Contrast',
        StyleDNAColors.contrast,
        Icons.contrast_outlined,
        [
          PropertyGauge(
            label: 'Dynamic Range',
            value: profile.contrast.dynamicRange,
            levels: const ['compressed', 'normal', 'wide', 'HDR'],
            color: StyleDNAColors.contrast,
          ),
          const SizedBox(height: 12),
          PropertyGauge(
            label: 'Shadows',
            value: profile.contrast.shadowDepth,
            levels: const ['lifted', 'medium', 'deep', 'crushed'],
            color: StyleDNAColors.contrast,
          ),
          const SizedBox(height: 12),
          _infoRow('Highlights', profile.contrast.highlightCharacter),
        ],
      ),

      // Atmosphere
      _buildSection(
        'Atmosphere',
        StyleDNAColors.atmosphere,
        Icons.cloud_outlined,
        [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MoodChip(
                  label: profile.atmosphere.mood,
                  color: StyleDNAColors.atmosphere),
              MoodChip(
                  label: profile.atmosphere.emotionalTone,
                  color: StyleDNAColors.atmosphere),
              MoodChip(
                  label: profile.atmosphere.genre,
                  color: StyleDNAColors.atmosphere),
            ],
          ),
        ],
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return sections[index]
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 80),
              duration: 400.ms,
            )
            .slideY(
              begin: 0.05,
              delay: Duration(milliseconds: index * 80),
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  Widget _buildSection(
      String title, Color color, IconData icon, List<Widget> children) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.headingSm.copyWith(
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
