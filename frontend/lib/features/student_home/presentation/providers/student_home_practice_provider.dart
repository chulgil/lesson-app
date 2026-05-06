import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../practice/practice_facade.dart';

part 'student_home_practice_provider.g.dart';

@riverpod
Future<List<PracticeLog>> studentHomePracticeLogs(
  StudentHomePracticeLogsRef ref,
  String studentId,
) {
  return ref.watch(practiceLogsProvider(studentId).future);
}
