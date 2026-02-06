// Re-export from domain/data layers for backward compatibility
// New code should import from:
//   - features/practice/domain/repositories/ for interfaces
//   - features/practice/data/repositories/ for implementations

export '../features/practice/domain/repositories/practice_goal_repository.dart';
export '../features/practice/data/repositories/mock_practice_goal_repository.dart';
