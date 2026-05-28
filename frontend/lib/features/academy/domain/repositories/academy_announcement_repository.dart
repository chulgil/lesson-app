import 'package:lessonaza/features/academy/domain/entities/academy_announcement.dart';

abstract class AcademyAnnouncementRepository {
  Future<List<AcademyAnnouncement>> listByAcademy(String academyId);
  Future<void> markAsRead(String announcementId);
}
