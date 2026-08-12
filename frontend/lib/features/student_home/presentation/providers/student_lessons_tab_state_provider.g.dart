// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_lessons_tab_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentSelectedDateHash() =>
    r'ed8d3c455fcbd541af68bd188a9d97edf4e1d27e';

/// State provider for student selected date
///
/// Copied from [StudentSelectedDate].
@ProviderFor(StudentSelectedDate)
final studentSelectedDateProvider =
    NotifierProvider<StudentSelectedDate, DateTime>.internal(
  StudentSelectedDate.new,
  name: r'studentSelectedDateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentSelectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudentSelectedDate = Notifier<DateTime>;
String _$studentLessonSortTypeHash() =>
    r'920f611c9afdf43d35e323a4e5e31aa1d904fb6e';

/// State provider for student lesson sort type. Persists the last selection
/// per student so it survives app restarts.
///
/// Copied from [StudentLessonSortType].
@ProviderFor(StudentLessonSortType)
final studentLessonSortTypeProvider =
    NotifierProvider<StudentLessonSortType, LessonSortType>.internal(
  StudentLessonSortType.new,
  name: r'studentLessonSortTypeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentLessonSortTypeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudentLessonSortType = Notifier<LessonSortType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
