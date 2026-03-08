import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/style_reference.dart';
import '../services/api_client.dart';
import '../services/style_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final styleServiceProvider = Provider<StyleService>((ref) {
  return StyleService(ref.read(apiClientProvider));
});

final styleLibraryProvider =
    AsyncNotifierProvider<StyleLibraryNotifier, List<StyleReference>>(
  StyleLibraryNotifier.new,
);

class StyleLibraryNotifier extends AsyncNotifier<List<StyleReference>> {
  @override
  Future<List<StyleReference>> build() async {
    return ref.read(styleServiceProvider).getStyles();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(styleServiceProvider).getStyles(),
    );
  }

  Future<void> deleteStyle(String id) async {
    await ref.read(styleServiceProvider).deleteStyle(id);
    await refresh();
  }
}
