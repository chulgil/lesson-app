/// User role enum for distinguishing teacher/student/parent views
enum UserRole { teacher, student, parent }

/// Mock student data for testing (when in student role)
class MockStudentInfo {
  final String id;
  final String name;

  const MockStudentInfo({required this.id, required this.name});
}
