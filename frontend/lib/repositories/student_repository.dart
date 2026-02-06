// Re-export from domain/data layer for backward compatibility
// New code should import from features/students/domain/repositories/ or features/students/data/repositories/

export '../features/students/domain/repositories/student_repository.dart';
export '../features/students/data/repositories/mock_student_repository.dart';
