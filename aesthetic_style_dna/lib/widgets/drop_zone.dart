import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';

class DropZone extends StatefulWidget {
  final void Function(File file) onFileDropped;
  final bool isProcessing;
  final FileType fileType;
  final List<String>? allowedExtensions;
  final String dropLabel;
  final String formatHint;
  final IconData icon;
  final IconData selectedIcon;

  const DropZone({
    super.key,
    required this.onFileDropped,
    this.isProcessing = false,
    this.fileType = FileType.image,
    this.allowedExtensions,
    this.dropLabel = 'Drop an image or click to browse',
    this.formatHint = 'PNG, JPG, WEBP up to 10MB',
    this.icon = Icons.cloud_upload_outlined,
    this.selectedIcon = Icons.image,
  });

  @override
  State<DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<DropZone>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  File? _selectedFile;
  late AnimationController _dashController;

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _dashController.dispose();
    super.dispose();
  }

  static const _imageExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.heic', '.heif',
  };

  bool _isAllowedFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (widget.fileType == FileType.custom && widget.allowedExtensions != null) {
      return widget.allowedExtensions!.contains(ext);
    }
    if (widget.fileType == FileType.image) {
      return _imageExtensions.contains('.$ext');
    }
    return true;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: widget.fileType,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() => _selectedFile = file);
      widget.onFileDropped(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final path = details.files.first.path;
          if (!_isAllowedFile(path)) return;
          final file = File(path);
          setState(() => _selectedFile = file);
          widget.onFileDropped(file);
        }
      },
      child: GestureDetector(
        onTap: widget.isProcessing ? null : _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 280),
          transform: Matrix4.identity()
            ..scale(_isDragging ? 1.02 : 1.0, _isDragging ? 1.02 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isDragging
                ? AppColors.accentPrimaryMuted
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: _isDragging
                ? Border.all(color: AppColors.accentPrimary, width: 2)
                : null,
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // Dashed border (only when not dragging)
              if (!_isDragging)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _dashController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _DashedBorderPainter(
                          color: widget.isProcessing
                              ? AppColors.accentPrimary
                              : AppColors.borderDefault,
                          strokeWidth: 1.5,
                          borderRadius: 20,
                          dashOffset: _dashController.value * 20,
                        ),
                      );
                    },
                  ),
                ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isDragging) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_rounded,
            size: 48,
            color: AppColors.accentPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Release to analyze',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.accentPrimary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.icon,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          widget.dropLabel,
          style: AppTypography.bodyLg,
        ),
        const SizedBox(height: 8),
        Text(
          widget.formatHint,
          style: AppTypography.bodySm,
        ),
        if (_selectedFile != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.selectedIcon, size: 16, color: AppColors.accentPrimary),
                const SizedBox(width: 8),
                Text(
                  _selectedFile!.path.split('/').last,
                  style: AppTypography.tag,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashOffset;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          strokeWidth / 2,
          strokeWidth / 2,
          size.width - strokeWidth,
          size.height - strokeWidth,
        ),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    const dashLength = 8.0;
    const gapLength = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = dashOffset % (dashLength + gapLength);
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          final end = min(distance + length, metric.length);
          dashPath.addPath(
            metric.extractPath(distance, end),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.dashOffset != dashOffset || old.color != color;
}
