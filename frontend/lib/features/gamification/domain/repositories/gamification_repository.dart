import '../entities/gamification.dart';

/// Repository interface for student gamification data.
abstract class GamificationRepository {
  Future<StudentGamification> getStudentGamification(String studentId);
}
