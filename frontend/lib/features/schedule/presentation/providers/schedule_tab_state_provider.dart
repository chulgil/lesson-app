import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../student_home/student_home_ui_facade.dart';

part 'schedule_tab_state_provider.g.dart';

/// State provider for teacher selected date
@Riverpod(keepAlive: true)
class TeacherSelectedDate extends _$TeacherSelectedDate {
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

/// State provider for teacher lesson sort type
@Riverpod(keepAlive: true)
class TeacherLessonSortType extends _$TeacherLessonSortType {
  @override
  LessonSortType build() => LessonSortType.timeAsc;

  @override
  LessonSortType get state => super.state;

  @override
  set state(LessonSortType value) => super.state = value;
}
