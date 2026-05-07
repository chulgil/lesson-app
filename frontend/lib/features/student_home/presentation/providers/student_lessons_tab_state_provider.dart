import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'student_lessons_tab_state_provider.g.dart';

/// Lesson sort type for schedule views
enum LessonSortType {
  timeAsc('시간순'),
  nameAsc('이름순');

  final String displayName;
  const LessonSortType(this.displayName);
}

/// State provider for student selected date
@Riverpod(keepAlive: true)
class StudentSelectedDate extends _$StudentSelectedDate {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  DateTime get state => super.state;

  @override
  set state(DateTime value) => super.state = value;
}

/// State provider for student lesson sort type
@Riverpod(keepAlive: true)
class StudentLessonSortType extends _$StudentLessonSortType {
  @override
  LessonSortType build() => LessonSortType.timeAsc;

  @override
  LessonSortType get state => super.state;

  @override
  set state(LessonSortType value) => super.state = value;
}
