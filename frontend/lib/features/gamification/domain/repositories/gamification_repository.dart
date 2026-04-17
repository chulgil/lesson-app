import '../entities/gamification.dart';

/// Repository interface for student gamification data.
abstract class GamificationRepository {
  Future<StudentGamification> getStudentGamification(String studentId);

  /// Persist newly earned badges for a student.
  Future<void> awardBadges(String studentId, List<PracticeBadge> badges);
}
