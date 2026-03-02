// Re-export from domain/data layer for backward compatibility
// New code should import from features/lessons/domain/repositories/ or features/lessons/data/repositories/

export '../features/lessons/domain/repositories/lesson_repository.dart';
export '../features/lessons/data/repositories/mock_lesson_repository.dart';
export '../features/lessons/data/repositories/remote_lesson_repository.dart';
