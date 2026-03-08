import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

Future<void> downloadFile({
  required String url,
  required String defaultFilename,
  required BuildContext context,
}) async {
  // Use save dialog — works within macOS sandbox
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: defaultFilename,
  );

  if (savePath == null) return; // User cancelled

  final resolvedUrl = url.startsWith('http') ? url : ApiConfig.outputUrl(url);

  try {
    await Dio().download(resolvedUrl, savePath);
    if (context.mounted) {
      _showSnackBar(context, 'Saved to ${savePath.split('/').last}');
    }
  } catch (e) {
    if (context.mounted) {
      _showSnackBar(context, 'Download failed: $e', isError: true);
    }
  }
}

void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
