import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/create_response.dart';
import 'style_library_provider.dart';

final transferStateProvider =
    AsyncNotifierProvider<TransferNotifier, CreateResponse?>(
  TransferNotifier.new,
);

class TransferNotifier extends AsyncNotifier<CreateResponse?> {
  @override
  Future<CreateResponse?> build() async => null;

  Future<void> transfer({
    required File image,
    required String styleId,
    int? seed,
    int width = 1024,
    int height = 1024,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(styleServiceProvider).transferImage(
            image: image,
            styleId: styleId,
            seed: seed,
            width: width,
            height: height,
          );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}
