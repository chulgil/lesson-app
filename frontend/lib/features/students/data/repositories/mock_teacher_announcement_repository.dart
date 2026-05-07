import '../../../lessons/domain/entities/entities.dart';
import '../../../lessons/domain/repositories/lesson_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/services/notification_service.dart';
import '../../domain/entities/teacher_announcement.dart';
import '../../domain/repositories/teacher_announcement_repository.dart';

/// Mock implementation of [TeacherAnnouncementRepository].
///
/// Stores announcements in memory. On create:
/// 1. Saves the announcement
/// 2. Finds affected lessons on day-off dates
/// 3. Sends notifications to affected students
class MockTeacherAnnouncementRepository
    implements TeacherAnnouncementRepository {
  final LessonRepository _lessonRepository;
  final NotificationService _notificationService;

  final List<TeacherAnnouncement> _store = [];

  MockTeacherAnnouncementRepository({
    required LessonRepository lessonRepository,
    required NotificationService notificationService,
  }) : _lessonRepository = lessonRepository,
       _notificationService = notificationService;

  @override
  Future<TeacherAnnouncement> create(TeacherAnnouncement announcement) async {
    // 1. 휴강 타입: 영향받는 레슨 조회
    var affectedLessons = <AffectedLesson>[];
    if (announcement.type == AnnouncementType.dayOff) {
      for (final date in announcement.dates) {
        final lessons = await _lessonRepository.getLessonsByDate(date);
        final cancellable = lessons.where(
          (l) =>
              l.status == LessonStatus.scheduled ||
              l.status == LessonStatus.reschedulePending,
        );
        for (final lesson in cancellable) {
          affectedLessons.add(
            AffectedLesson(
              studentId: lesson.studentId,
              studentName: lesson.studentName,
              instrument: lesson.instrument,
              startTime: lesson.startTime,
              subscriptionId: lesson.subscriptionId,
            ),
          );
        }
      }
    }

    // 2. 공지 저장
    final saved = TeacherAnnouncement(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: announcement.teacherId,
      type: announcement.type,
      dates: announcement.dates,
      message: announcement.message,
      createdAt: DateTime.now(),
      affectedLessons: affectedLessons,
    );
    _store.add(saved);

    // 3. 활성 수강권 학생 전원에게 알림 발송
    await _notifyAllActiveStudents(saved);

    return saved;
  }

  @override
  Future<TeacherAnnouncement> update(TeacherAnnouncement announcement) async {
    final index = _store.indexWhere((a) => a.id == announcement.id);
    if (index >= 0) {
      _store[index] = announcement;
    }
    return announcement;
  }

  @override
  Future<void> delete(String id) async {
    _store.removeWhere((a) => a.id == id);
  }

  @override
  Future<List<TeacherAnnouncement>> getByTeacherId(String teacherId) async {
    return _store
        .where((a) => a.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<DateTime>> getDayOffs({
    required String teacherId,
    required DateTime from,
    required DateTime to,
  }) async {
    final dayOffs = <DateTime>[];
    for (final announcement in _store) {
      if (announcement.teacherId != teacherId) continue;
      if (announcement.type != AnnouncementType.dayOff) continue;
      for (final date in announcement.dates) {
        final normalized = DateTime(date.year, date.month, date.day);
        if (!normalized.isBefore(from) && !normalized.isAfter(to)) {
          dayOffs.add(normalized);
        }
      }
    }
    return dayOffs;
  }

  Future<void> _notifyAllActiveStudents(TeacherAnnouncement announcement) async {
    // 간단 구현: 영향받는 학생에게만 알림 (실제로는 전체 활성 학생)
    final studentIds = <String>{};

    // 영향받는 학생
    for (final lesson in announcement.affectedLessons) {
      studentIds.add(lesson.studentId);
    }

    final title = announcement.type == AnnouncementType.dayOff
        ? '휴강 안내'
        : '선생님 공지';

    for (final studentId in studentIds) {
      final notification = AppNotification(
        id: 'ann_notif_${announcement.id}_$studentId',
        userId: studentId,
        type: NotificationType.generalAnnouncement,
        priority: announcement.type == AnnouncementType.dayOff
            ? NotificationPriority.high
            : NotificationPriority.normal,
        title: title,
        body: announcement.message,
        createdAt: DateTime.now(),
        data: {
          'teacherId': announcement.teacherId,
          'announcementId': announcement.id,
          'type': announcement.type.name,
          'source': 'teacher_announcement',
        },
      );
      await _notificationService.showNotification(notification);
    }
  }
}
