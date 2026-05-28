import 'package:lessonaza/features/academy/domain/entities/academy_activity_log.dart';

abstract class AcademyActivityRepository {
  /// List activity logs for teacher's own academy (actor_member_id = me)
  /// Returns logs sorted by createdAt descending (newest first)
  Future<List<AcademyActivityLog>> listByAcademyAndActor(
    String academyId,
    String actorMemberId,
  );
}
