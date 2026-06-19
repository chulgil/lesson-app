// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonSelectionHash() => r'02743f86f56b60c941bbd37b7aad91f5b5631d3d';

/// Multi-select state for the schedule lesson list (#768 ①).
///
/// Selection mode is active iff the set is non-empty: a long-press enters the
/// mode (selecting that lesson), tapping toggles others, and clearing the last
/// item exits. Holds the selected lesson ids only.
///
/// Copied from [LessonSelection].
@ProviderFor(LessonSelection)
final lessonSelectionProvider =
    AutoDisposeNotifierProvider<LessonSelection, Set<String>>.internal(
  LessonSelection.new,
  name: r'lessonSelectionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonSelection = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
