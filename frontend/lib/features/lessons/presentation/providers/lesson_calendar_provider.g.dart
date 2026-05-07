// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedDateLessonsHash() =>
    r'8843ead1531a28c476604b252005215c3efde3a2';

/// Lessons for selected date
///
/// Copied from [selectedDateLessons].
@ProviderFor(selectedDateLessons)
final selectedDateLessonsProvider = FutureProvider<List<Lesson>>.internal(
  selectedDateLessons,
  name: r'selectedDateLessonsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedDateLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SelectedDateLessonsRef = FutureProviderRef<List<Lesson>>;
String _$monthLessonsHash() => r'5a3a424abe903be51833a57872bd8fdc2bf015d5';

/// See also [monthLessons].
@ProviderFor(monthLessons)
final monthLessonsProvider = FutureProvider<List<Lesson>>.internal(
  monthLessons,
  name: r'monthLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$monthLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MonthLessonsRef = FutureProviderRef<List<Lesson>>;
String _$lessonsMapHash() => r'973ebf1b8281f5f26bda29d9962e71c263e667be';

/// Lessons grouped by date for calendar
///
/// Copied from [lessonsMap].
@ProviderFor(lessonsMap)
final lessonsMapProvider =
    Provider<AsyncValue<Map<DateTime, List<Lesson>>>>.internal(
  lessonsMap,
  name: r'lessonsMapProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lessonsMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LessonsMapRef = ProviderRef<AsyncValue<Map<DateTime, List<Lesson>>>>;
String _$weekLessonsHash() => r'0ddf6a7b9f1811d6f9cd93e3ce3676b4e4a49a9d';

/// Lessons for selected week
///
/// Copied from [weekLessons].
@ProviderFor(weekLessons)
final weekLessonsProvider = FutureProvider<List<Lesson>>.internal(
  weekLessons,
  name: r'weekLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$weekLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeekLessonsRef = FutureProviderRef<List<Lesson>>;
String _$weekLessonsMapHash() => r'ea3a4b7b7468f11b24e4a107f8fedf3fcc14475f';

/// Lessons grouped by day index for week view
///
/// Copied from [weekLessonsMap].
@ProviderFor(weekLessonsMap)
final weekLessonsMapProvider =
    Provider<AsyncValue<Map<int, List<Lesson>>>>.internal(
  weekLessonsMap,
  name: r'weekLessonsMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$weekLessonsMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WeekLessonsMapRef = ProviderRef<AsyncValue<Map<int, List<Lesson>>>>;
String _$selectedDateHash() => r'6c5aaff4ab7a60d19b71fad710e7ae68079b053d';

/// Selected date for calendar
///
/// Copied from [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider = NotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = Notifier<DateTime>;
String _$calendarMonthHash() => r'f55a33381fa28ec7e84bbfb20b33420daa30c275';

/// Lessons for calendar view (month range)
///
/// Copied from [CalendarMonth].
@ProviderFor(CalendarMonth)
final calendarMonthProvider =
    NotifierProvider<CalendarMonth, DateTime>.internal(
  CalendarMonth.new,
  name: r'calendarMonthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$calendarMonthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CalendarMonth = Notifier<DateTime>;
String _$selectedWeekStartHash() => r'47fbf9f92698151f2ce6d03b50303e9a246bcc29';

/// Selected week start for calendar
///
/// Copied from [SelectedWeekStart].
@ProviderFor(SelectedWeekStart)
final selectedWeekStartProvider =
    NotifierProvider<SelectedWeekStart, DateTime>.internal(
  SelectedWeekStart.new,
  name: r'selectedWeekStartProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedWeekStartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedWeekStart = Notifier<DateTime>;
String _$selectedDayIndexHash() => r'd782c1806bec190a2e44079b72f355ed19a8990a';

/// Selected day index for calendar (0 = Monday)
///
/// Copied from [SelectedDayIndex].
@ProviderFor(SelectedDayIndex)
final selectedDayIndexProvider =
    NotifierProvider<SelectedDayIndex, int>.internal(
  SelectedDayIndex.new,
  name: r'selectedDayIndexProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedDayIndexHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDayIndex = Notifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
