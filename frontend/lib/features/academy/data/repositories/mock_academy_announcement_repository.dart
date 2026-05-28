import 'package:lessonaza/features/academy/domain/entities/academy_announcement.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_announcement_repository.dart';

class MockAcademyAnnouncementRepository
    implements AcademyAnnouncementRepository {
  final Map<String, AcademyAnnouncement> _announcements = {
    'ann_001': AcademyAnnouncement(
      id: 'ann_001',
      academyId: 'acad_001',
      title: '여름 방학 수강 안내',
      body: '올해 여름 방학은 7월 22일부터 8월 18일까지입니다.\n수강권 유효기간 안내 및 휴강 신청을 미리 부탁드립니다.',
      sentAt: DateTime.now().subtract(const Duration(days: 5)),
      isRead: false,
    ),
    'ann_002': AcademyAnnouncement(
      id: 'ann_002',
      academyId: 'acad_001',
      title: '신학기 시간표 변경 안내',
      body: '4월부터 새로운 수업 시간표가 적용됩니다.\n개인별 일정 확인 부탁드립니다.',
      sentAt: DateTime.now().subtract(const Duration(days: 10)),
      isRead: true,
    ),
    'ann_003': AcademyAnnouncement(
      id: 'ann_003',
      academyId: 'acad_001',
      title: '악기 정기점검 안내',
      body: '모든 악기 정기점검이 예정되어 있습니다.\n자세한 일정은 학원에서 공지하겠습니다.',
      sentAt: DateTime.now().subtract(const Duration(days: 15)),
      isRead: true,
    ),
  };

  @override
  Future<List<AcademyAnnouncement>> listByAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list =
        _announcements.values.where((a) => a.academyId == academyId).toList();
    return list..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  @override
  Future<void> markAsRead(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_announcements.containsKey(announcementId)) {
      final announcement = _announcements[announcementId]!;
      _announcements[announcementId] = announcement.copyWith(isRead: true);
    }
  }
}
