import '../../../lessons/domain/entities/entities.dart';
import '../../../lessons/domain/repositories/lesson_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/services/notification_service.dart';
import '../entities/bulk_cancel_result.dart';

/// §7.119 Bulk Teacher Actions — 선택 모드에서 선생님이 여러 학생에게 동시 실행하는 운영 작업.
///
/// 지원 유스케이스:
/// - B1 휴강 공지: 특정 날짜의 레슨을 일괄 취소 + lessonCancelled 알림
/// - B2 일괄 메시지: 학생들에게 generalAnnouncement 알림 브로드캐스트
///
/// "수강권 일괄 발급" 경로는 §7.119에서 제거되었다. 해당 루트는
/// studentIds.first 로만 실행되는 silent drop 버그가 있었고, UX적으로도
/// 수강권은 학생별 개별 설계가 필요하기 때문.
class BulkTeacherActionService {
  final LessonRepository _lessonRepository;
  final NotificationService _notificationService;

  BulkTeacherActionService({
    required LessonRepository lessonRepository,
    required NotificationService notificationService,
  }) : _lessonRepository = lessonRepository,
       _notificationService = notificationService;

  /// 대상 날짜에 예정된 레슨을 일괄 취소하고 각 학생에게 알림을 보낸다.
  ///
  /// - 대상 날짜에 scheduled 상태 레슨이 없는 학생은 [BulkCancelResult.skippedStudentIds] 에 포함
  /// - 이미 취소 상태인 레슨은 건드리지 않는다 (중복 취소 방지)
  Future<BulkCancelResult> cancelLessonsOnDate({
    required String teacherId,
    required List<String> studentIds,
    required DateTime targetDate,
    String? reason,
  }) async {
    final lessonsOnDate = await _lessonRepository.getLessonsByDate(targetDate);
    final lessonsByStudent = <String, Lesson>{
      for (final lesson in lessonsOnDate)
        if (_isCancellable(lesson) && studentIds.contains(lesson.studentId))
          lesson.studentId: lesson,
    };

    final skipped = <String>[];
    for (final studentId in studentIds) {
      if (!lessonsByStudent.containsKey(studentId)) {
        skipped.add(studentId);
      }
    }

    var cancelledCount = 0;
    var notifiedCount = 0;
    for (final entry in lessonsByStudent.entries) {
      final lesson = entry.value;
      await _lessonRepository.cancelLesson(lesson.id);
      cancelledCount++;

      await _notifyCancellation(
        studentId: entry.key,
        teacherId: teacherId,
        lesson: lesson,
        reason: reason,
      );
      notifiedCount++;
    }

    return BulkCancelResult(
      cancelledLessonCount: cancelledCount,
      notifiedStudentCount: notifiedCount,
      skippedStudentIds: skipped,
    );
  }

  /// 선생님 공지 메시지를 선택된 모든 학생에게 generalAnnouncement 알림으로 발송.
  ///
  /// 반환: 실제로 알림을 받은 학생 수.
  Future<int> broadcastMessage({
    required String teacherId,
    required List<String> studentIds,
    required String title,
    required String body,
  }) async {
    if (studentIds.isEmpty) return 0;

    final now = DateTime.now();
    var sent = 0;
    for (final studentId in studentIds) {
      final notification = AppNotification(
        id: 'bulk_msg_${now.millisecondsSinceEpoch}_$studentId',
        userId: studentId,
        type: NotificationType.generalAnnouncement,
        priority: NotificationPriority.normal,
        title: title,
        body: body,
        createdAt: now,
        data: {'teacherId': teacherId, 'source': 'bulk_teacher_action'},
      );
      await _notificationService.showNotification(notification);
      sent++;
    }
    return sent;
  }

  /// 대상 날짜에서 취소 대상이 될 레슨 목록을 mutation 없이 반환 (확인 다이얼로그용).
  Future<List<Lesson>> previewAffectedLessons({
    required List<String> studentIds,
    required DateTime targetDate,
  }) async {
    final lessons = await _lessonRepository.getLessonsByDate(targetDate);
    return lessons
        .where((l) => _isCancellable(l) && studentIds.contains(l.studentId))
        .toList();
  }

  bool _isCancellable(Lesson lesson) {
    switch (lesson.status) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return true;
      default:
        return false;
    }
  }

  Future<void> _notifyCancellation({
    required String studentId,
    required String teacherId,
    required Lesson lesson,
    String? reason,
  }) async {
    final bodyBuffer = StringBuffer(
      '${_formatDate(lesson.date)} ${lesson.startTime} 레슨이 취소되었습니다',
    );
    if (reason != null && reason.trim().isNotEmpty) {
      bodyBuffer.write(' — ${reason.trim()}');
    }

    final notification = AppNotification(
      id: 'bulk_cancel_${DateTime.now().millisecondsSinceEpoch}_$studentId',
      userId: studentId,
      type: NotificationType.lessonCancelled,
      priority: NotificationPriority.high,
      title: '휴강 안내',
      body: bodyBuffer.toString(),
      createdAt: DateTime.now(),
      data: {
        'teacherId': teacherId,
        'lessonId': lesson.id,
        'source': 'bulk_teacher_action',
      },
    );
    await _notificationService.showNotification(notification);
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}
