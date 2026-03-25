import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/grouped_students.dart';
import '../../domain/entities/lesson_class.dart';
import '../../domain/entities/student_with_membership.dart';
import '../widgets/student_subscription_badge.dart';
import 'lesson_class_providers.dart';
import 'membership_providers.dart';
import 'student_crud_provider.dart';

part 'grouped_students_provider.g.dart';

/// ClassTypeFilter state managed by Riverpod.
@riverpod
class ClassTypeFilterNotifier extends _$ClassTypeFilterNotifier {
  @override
  ClassTypeFilter build() => ClassTypeFilter.all;

  void set(ClassTypeFilter filter) => state = filter;
}

/// Groups students by their LessonClass membership.
@riverpod
Future<List<StudentGroup>> groupedStudents(
  GroupedStudentsRef ref,
  String teacherId,
) async {
  // 1. Get all classes sorted by sortOrder
  final classes =
      await ref.watch(teacherLessonClassesProvider(teacherId).future);

  // 2. Get all students
  final students = await ref.watch(studentsNotifierProvider.future);
  final studentMap = {for (final s in students) s.id: s};

  // 3. Track categorized student IDs
  final categorizedStudentIds = <String>{};

  // 4. Build groups per class
  final groups = <StudentGroup>[];

  for (final lessonClass in classes) {
    final memberships =
        await ref.watch(classMembershipsProvider(lessonClass.id).future);

    // Only enrolled (trial or active) memberships
    final enrolled = memberships.where((m) => m.isEnrolled).toList();

    final studentsInClass = <StudentWithMembership>[];
    for (final membership in enrolled) {
      final student = studentMap[membership.studentId];
      if (student != null) {
        studentsInClass.add(StudentWithMembership(
          student: student,
          membership: membership,
        ));
        categorizedStudentIds.add(membership.studentId);
      }
    }

    if (studentsInClass.isNotEmpty) {
      groups.add(StudentGroup(
        lessonClass: lessonClass,
        students: studentsInClass,
      ));
    }
  }

  // 5. Uncategorized students (no enrolled membership in any class)
  final uncategorized = students
      .where((s) => !categorizedStudentIds.contains(s.id))
      .map((s) => StudentWithMembership(student: s))
      .toList();

  if (uncategorized.isNotEmpty) {
    groups.add(StudentGroup(students: uncategorized));
  }

  return groups;
}

/// Filtered grouped students - applies ClassTypeFilter and search query.
@riverpod
Future<List<StudentGroup>> filteredGroupedStudents(
  FilteredGroupedStudentsRef ref,
  String teacherId,
) async {
  final groups = await ref.watch(groupedStudentsProvider(teacherId).future);
  final classTypeFilter = ref.watch(classTypeFilterNotifierProvider);
  final searchQuery = ref.watch(studentSearchQueryProvider).toLowerCase();

  var result = groups;

  // Apply class type filter
  if (classTypeFilter != ClassTypeFilter.all) {
    result = result.where((group) {
      if (group.lessonClass == null) return false;
      return classTypeFilter == ClassTypeFilter.academy
          ? group.classType == LessonClassType.academy
          : group.classType == LessonClassType.private;
    }).toList();
  }

  // Apply search filter
  if (searchQuery.isNotEmpty) {
    result = result
        .map((group) {
          final filtered = group.students
              .where((swm) =>
                  swm.name.toLowerCase().contains(searchQuery) ||
                  swm.instrument.toLowerCase().contains(searchQuery))
              .toList();
          return StudentGroup(
            lessonClass: group.lessonClass,
            students: filtered,
          );
        })
        .where((group) => group.students.isNotEmpty)
        .toList();
  }

  return result;
}
