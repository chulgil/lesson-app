import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/practice_item.dart';
import '../../../../providers/providers.dart';

/// Summary of weekly assignment progress across all students.
class WeeklyAssignmentSummary {
  final int totalItems;
  final int completedItems;
  final List<StudentAssignmentStatus> incompleteStudents;

  const WeeklyAssignmentSummary({
    required this.totalItems,
    required this.completedItems,
    required this.incompleteStudents,
  });

  double get completionRate =>
      totalItems == 0 ? 1.0 : completedItems / totalItems;
}

/// Assignment status for a single student.
class StudentAssignmentStatus {
  final String studentId;
  final String studentName;
  final int totalItems;
  final int completedItems;
  final PracticeItem? mostUrgentItem;

  const StudentAssignmentStatus({
    required this.studentId,
    required this.studentName,
    required this.totalItems,
    required this.completedItems,
    this.mostUrgentItem,
  });

  int get incompleteCount => totalItems - completedItems;
}

/// Provider for weekly assignment summary (home dashboard).
final weeklyAssignmentSummaryProvider =
    FutureProvider<WeeklyAssignmentSummary>((ref) async {
  final students = await ref.watch(studentsProvider.future);
  final repository = ref.watch(practiceItemRepositoryProvider);

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  int totalItems = 0;
  int completedItems = 0;
  final incompleteStudents = <StudentAssignmentStatus>[];

  for (final student in students) {
    final items = await repository.getByStudentIdAndDateRange(
      student.id,
      startOfWeek,
      endOfWeek,
    );
    if (items.isEmpty) continue;

    final completed = items.where((i) => i.isCompleted).length;
    totalItems += items.length;
    completedItems += completed;

    if (completed < items.length) {
      final incomplete = items.where((i) => !i.isCompleted).toList();
      incompleteStudents.add(StudentAssignmentStatus(
        studentId: student.id,
        studentName: student.name,
        totalItems: items.length,
        completedItems: completed,
        mostUrgentItem: incomplete.isNotEmpty ? incomplete.first : null,
      ));
    }
  }

  // Sort by most incomplete first
  incompleteStudents.sort(
    (a, b) => b.incompleteCount.compareTo(a.incompleteCount),
  );

  return WeeklyAssignmentSummary(
    totalItems: totalItems,
    completedItems: completedItems,
    incompleteStudents: incompleteStudents,
  );
});
