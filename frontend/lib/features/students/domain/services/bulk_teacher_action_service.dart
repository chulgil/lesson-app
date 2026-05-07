import '../../../lessons/domain/entities/entities.dart';
import '../../../lessons/domain/repositories/lesson_repository.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/domain/services/notification_service.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../../schedule/domain/repositories/unified_lesson_request_repository.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/domain/repositories/subscription_repository.dart';
import '../entities/bulk_cancel_result.dart';

/// §7.119 v2 Bulk Teacher Actions — 선택 모드에서 선생님이 여러 학생에게 동시 실행하는 운영 작업.
///
/// 지원 유스케이스:
/// - B1 휴강 공지: 특정 날짜의 레슨을 일괄 취소 + RequestEvent + 알림
/// - B2 일괄 메시지: 학생들에게 공지 알림 + RequestEvent 브로드캐스트
///
/// v2 변경 (2026-05-07):
/// - 회차(sessionNumber) 매핑 + 수강권 챗 이벤트(RequestEvent) 생성
/// - 수강권 미발급 학생 자동 제외
/// - 일괄 메시지 수신 조건 필터 (활성 수강권만 / 전체)
class BulkTeacherActionService {
  final LessonRepository _lessonRepository;
  final NotificationService _notificationService;
  final UnifiedLessonRequestRepository _requestRepository;
  final SubscriptionRepository _subscriptionRepository;

  BulkTeacherActionService({
    required LessonRepository lessonRepository,
    required NotificationService notificationService,
    required UnifiedLessonRequestRepository requestRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _lessonRepository = lessonRepository,
       _notificationService = notificationService,
       _requestRepository = requestRepository,
       _subscriptionRepository = subscriptionRepository;

  /// 대상 날짜에 예정된 레슨을 일괄 취소하고 각 학생에게 알림을 보낸다.
  ///
  /// - 대상 날짜에 scheduled 상태 레슨이 없는 학생은 [BulkCancelResult.skippedStudentIds] 에 포함
  /// - 이미 취소 상태인 레슨은 건드리지 않는다 (중복 취소 방지)
  /// - 상태는 [LessonStatus.cancelledByTeacher] 로 명시 설정 → 차감 없음(`isDeducted=false`)
  ///   + 학생 측 reschedule 요청 가능(`allowsReschedule=true`) 보장. 일반
  ///   `cancelLesson()` 는 generic [LessonStatus.cancelled] 로 떨어져 reschedule 경로가
  ///   막히기 때문에 사용하지 않는다.
  /// 대상 날짜에 **수업이 있는 학생만** 일괄 취소.
  ///
  /// 필터링 순서:
  /// 1. targetDate에 예정된 레슨 조회 (`getLessonsByDate`)
  /// 2. `scheduled` / `reschedulePending` 상태만 (`_isCancellable`)
  /// 3. 선택된 studentIds에 포함된 학생만
  /// 4. 활성 수강권 없는 학생은 skipped (수강권 미발급 제외)
  ///
  /// → **수업일이 아닌 학생**은 자동으로 skipped에 포함.
  Future<BulkCancelResult> cancelLessonsOnDate({
    required String teacherId,
    required List<String> studentIds,
    required DateTime targetDate,
    required String notificationTitle,
    String? reason,
  }) async {
    final lessonsOnDate = await _lessonRepository.getLessonsByDate(targetDate);

    // 활성 수강권 보유 학생만 필터
    final activeStudents = await _filterActiveSubscriptionStudents(studentIds);
    final activeStudentSet = activeStudents.toSet();

    final lessonsByStudent = <String, Lesson>{
      for (final lesson in lessonsOnDate)
        if (_isCancellable(lesson) &&
            activeStudentSet.contains(lesson.studentId))
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
      await _lessonRepository.updateLesson(
        lesson.copyWith(
          status: LessonStatus.cancelledByTeacher,
          updatedAt: DateTime.now(),
        ),
      );
      cancelledCount++;

      // v2: 수강권 챗에 RequestEvent 생성 (회차 매핑)
      await _createCancelEvent(
        teacherId: teacherId,
        lesson: lesson,
        reason: reason,
      );

      await _notifyCancellation(
        studentId: entry.key,
        teacherId: teacherId,
        lesson: lesson,
        title: notificationTitle,
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

  /// 선생님 공지 메시지를 학생들에게 generalAnnouncement 알림으로 발송.
  ///
  /// [activeOnly] = true: 활성 수강권 보유 학생만 (기본)
  /// [activeOnly] = false: 선택된 전체 학생
  ///
  /// 활성 수강권 보유 학생에게는 수강권 챗에도 RequestEvent 생성.
  /// 반환: 실제로 알림을 받은 학생 수.
  Future<int> broadcastMessage({
    required String teacherId,
    required List<String> studentIds,
    required String title,
    required String body,
    bool activeOnly = true,
  }) async {
    if (studentIds.isEmpty) return 0;

    // 수신 대상 필터링
    final targetIds =
        activeOnly
            ? await _filterActiveSubscriptionStudents(studentIds)
            : studentIds;

    final now = DateTime.now();
    var sent = 0;
    for (final studentId in targetIds) {
      // 알림 생성
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

      // v2: 활성 수강권이 있으면 챗에 RequestEvent 생성
      await _createAnnouncementEvent(
        teacherId: teacherId,
        studentId: studentId,
        title: title,
        body: body,
      );

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
    required String title,
    String? reason,
  }) async {
    final subscription = await _subscriptionForLesson(lesson);
    final session = _sessionNumberFor(subscription);
    final sessionPrefix = session != null ? '$session회차 ' : '';
    final bodyBuffer = StringBuffer(
      '$sessionPrefix${_formatDate(lesson.date)} ${lesson.startTime} 레슨이 취소되었습니다',
    );
    if (reason != null && reason.trim().isNotEmpty) {
      bodyBuffer.write(' — ${reason.trim()}');
    }

    final notification = AppNotification(
      id: 'bulk_cancel_${DateTime.now().millisecondsSinceEpoch}_$studentId',
      userId: studentId,
      type: NotificationType.lessonCancelled,
      priority: NotificationPriority.high,
      title: title,
      body: bodyBuffer.toString(),
      createdAt: DateTime.now(),
      data: {
        'teacherId': teacherId,
        'lessonId': lesson.id,
        'sessionNumber': session,
        'source': 'bulk_teacher_action',
      },
    );
    await _notificationService.showNotification(notification);
  }

  /// v2: 수강권 챗에 lessonCancelledByTeacher 이벤트 생성.
  Future<void> _createCancelEvent({
    required String teacherId,
    required Lesson lesson,
    String? reason,
  }) async {
    final subscriptionId = lesson.subscriptionId;
    if (subscriptionId == null) return;

    final sub = await _subscriptionForLesson(lesson);
    final requestId = await _requestIdForStudentTeacher(
      studentId: lesson.studentId,
      teacherId: teacherId,
    );
    if (requestId == null) return;

    final event = RequestEvent(
      id: 'cancel_event_${DateTime.now().millisecondsSinceEpoch}_${lesson.id}',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.lessonCancelledByTeacher,
      subscriptionId: subscriptionId,
      sessionNumber: _sessionNumberFor(sub),
      message: reason,
      changeCreditUsed: 0,
      changeCreditRemainingAfter: sub?.remainingReschedule,
      keepsSessionNumber: true,
      createdAt: DateTime.now(),
    );
    await _requestRepository.addEvent(event);
  }

  /// v2: 수강권 챗에 teacherAnnouncement 이벤트 생성.
  Future<void> _createAnnouncementEvent({
    required String teacherId,
    required String studentId,
    required String title,
    required String body,
  }) async {
    final requestId = await _requestIdForStudentTeacher(
      studentId: studentId,
      teacherId: teacherId,
    );
    if (requestId == null) return;

    final subs = await _subscriptionRepository.getByStudentId(studentId);
    final activeSub = subs.where(_isActiveSubscription).firstOrNull;

    final event = RequestEvent(
      id: 'announce_${DateTime.now().millisecondsSinceEpoch}_$studentId',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.teacherAnnouncement,
      subscriptionId: activeSub?.id,
      message: '$title\n$body',
      createdAt: DateTime.now(),
    );
    await _requestRepository.addEvent(event);
  }

  /// v2: 활성 수강권 보유 학생만 필터.
  Future<List<String>> _filterActiveSubscriptionStudents(
    List<String> studentIds,
  ) async {
    final result = <String>[];
    for (final studentId in studentIds) {
      final subs = await _subscriptionRepository.getByStudentId(studentId);
      if (subs.any(_isActiveSubscription)) {
        result.add(studentId);
      }
    }
    return result;
  }

  bool _isActiveSubscription(Subscription sub) {
    return sub.status == SubscriptionStatus.active ||
        sub.status == SubscriptionStatus.expiringSoon;
  }

  Future<Subscription?> _subscriptionForLesson(Lesson lesson) async {
    final subscriptionId = lesson.subscriptionId;
    if (subscriptionId == null) return null;

    final subs = await _subscriptionRepository.getByStudentId(lesson.studentId);
    return subs.where((s) => s.id == subscriptionId).firstOrNull;
  }

  int? _sessionNumberFor(Subscription? subscription) {
    if (subscription == null) return null;
    return subscription.usedLessons + 1;
  }

  Future<String?> _requestIdForStudentTeacher({
    required String studentId,
    required String teacherId,
  }) async {
    final requests = await _requestRepository.getByStudentId(studentId);
    final matching =
        requests.where((request) => request.teacherId == teacherId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matching.firstOrNull?.id;
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}
