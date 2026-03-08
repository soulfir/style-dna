import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_response.dart';
import 'style_library_provider.dart';

final createStateProvider =
    AsyncNotifierProvider<CreateNotifier, CreateResponse?>(
  CreateNotifier.new,
);

class CreateNotifier extends AsyncNotifier<CreateResponse?> {
  @override
  Future<CreateResponse?> build() async => null;

  Future<void> generate({
    required List<String> styleIds,
    String? prompt,
    int? seed,
    int width = 1024,
    int height = 1024,
    File? referenceImage,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(styleServiceProvider).createImage(
            styleIds: styleIds,
            prompt: prompt,
            seed: seed,
            width: width,
            height: height,
            referenceImage: referenceImage,
          );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
