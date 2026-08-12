// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_tab_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherSelectedDateHash() =>
    r'fa52e8e511b117c692c63f57122f70d87f650ca4';

/// State provider for teacher selected date
///
/// Copied from [TeacherSelectedDate].
@ProviderFor(TeacherSelectedDate)
final teacherSelectedDateProvider =
    NotifierProvider<TeacherSelectedDate, DateTime>.internal(
  TeacherSelectedDate.new,
  name: r'teacherSelectedDateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSelectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSelectedDate = Notifier<DateTime>;
String _$teacherLessonSortTypeHash() =>
    r'a3df1292c5f70c75d680dda5d9adffa46d07f7a2';

/// State provider for teacher lesson sort type. Persists the last selection
/// per teacher so it survives app restarts.
///
/// Copied from [TeacherLessonSortType].
@ProviderFor(TeacherLessonSortType)
final teacherLessonSortTypeProvider =
    NotifierProvider<TeacherLessonSortType, LessonSortType>.internal(
  TeacherLessonSortType.new,
  name: r'teacherLessonSortTypeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherLessonSortTypeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherLessonSortType = Notifier<LessonSortType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
