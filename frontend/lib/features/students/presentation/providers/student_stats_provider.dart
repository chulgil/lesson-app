import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/students/domain/entities/student.dart';
import 'student_crud_provider.dart';

/// Students grouped by practice status
final studentsByStatusProvider =
    Provider<AsyncValue<Map<PracticeStatus, List<Student>>>>((ref) {
  final studentsAsync = ref.watch(studentsNotifierProvider);

  return studentsAsync.when(
    data: (students) {
      final grouped = <PracticeStatus, List<Student>>{};
      for (final status in PracticeStatus.values) {
        grouped[status] =
            students.where((s) => s.practiceStatus == status).toList();
      }
      return AsyncValue.data(grouped);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Students count by status for dashboard
final studentCountsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final studentsAsync = ref.watch(studentsNotifierProvider);

  return studentsAsync.when(
    data: (students) {
      final activeStudents = students.where((s) => s.isActive).toList();
      return AsyncValue.data({
        'total': activeStudents.length,
        'good': activeStudents
            .where((s) => s.practiceStatus == PracticeStatus.good)
            .length,
        'normal': activeStudents
            .where((s) => s.practiceStatus == PracticeStatus.normal)
            .length,
        'poor': activeStudents
            .where((s) => s.practiceStatus == PracticeStatus.poor)
            .length,
        'paused': activeStudents
            .where((s) => s.practiceStatus == PracticeStatus.paused)
            .length,
      });
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
