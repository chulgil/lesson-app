import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lesson_selection_provider.g.dart';

/// Multi-select state for the schedule lesson list (#768 ①).
///
/// Selection mode is active iff the set is non-empty: a long-press enters the
/// mode (selecting that lesson), tapping toggles others, and clearing the last
/// item exits. Holds the selected lesson ids only.
@riverpod
class LessonSelection extends _$LessonSelection {
  @override
  Set<String> build() => const <String>{};

  /// Add the lesson if absent, remove it if present.
  void toggle(String lessonId) {
    final next = Set<String>.from(state);
    if (!next.add(lessonId)) next.remove(lessonId);
    state = next;
  }

  /// Replace the selection with exactly [lessonIds] (used by "select all").
  void selectAll(Iterable<String> lessonIds) {
    state = Set<String>.from(lessonIds);
  }

  /// Exit selection mode.
  void clear() {
    if (state.isEmpty) return;
    state = const <String>{};
  }
}
