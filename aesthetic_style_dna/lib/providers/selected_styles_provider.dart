import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedStylesProvider =
    NotifierProvider<SelectedStylesNotifier, Set<String>>(
  SelectedStylesNotifier.new,
);

class SelectedStylesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String styleId) {
    if (state.contains(styleId)) {
      state = {...state}..remove(styleId);
    } else {
      if (state.length >= 3) return; // max 3 styles
      state = {...state, styleId};
    }
  }

  void remove(String styleId) {
    state = {...state}..remove(styleId);
  }

  void setStyles(Set<String> ids) {
    state = ids.take(3).toSet();
  }

  void clear() {
    state = {};
  }
}
