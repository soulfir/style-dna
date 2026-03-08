import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analyze_response.dart';
import 'style_library_provider.dart';

final analyzeStateProvider =
    AsyncNotifierProvider<AnalyzeNotifier, AnalyzeResponse?>(
  AnalyzeNotifier.new,
);

class AnalyzeNotifier extends AsyncNotifier<AnalyzeResponse?> {
  @override
  Future<AnalyzeResponse?> build() async => null;

  Future<void> analyze(File imageFile, {String? customTag}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(styleServiceProvider)
          .analyzeImage(imageFile, customTag: customTag);
      ref.invalidate(styleLibraryProvider);
      return result;
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
