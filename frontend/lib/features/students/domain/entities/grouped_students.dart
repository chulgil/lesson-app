import 'lesson_class.dart';
import 'student_with_membership.dart';

/// A group of students belonging to the same LessonClass.
class StudentGroup {
  final LessonClass? lessonClass; // null = uncategorized
  final List<StudentWithMembership> students;

  const StudentGroup({
    this.lessonClass,
    required this.students,
  });

  String get title => lessonClass?.name ?? '미분류';
  String get icon => lessonClass?.icon ?? '📋';
  int get count => students.length;
  LessonClassType? get classType => lessonClass?.type;
}
