import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/schedule/presentation/services/booking_notification_service.dart';

/// #541: 협상 이벤트(제안/수락/거절/역제안)가 상대에게 AppNotification 을 만든다.
/// 각 메서드가 올바른 수신자(userId=상대)·타입·역할 문구를 생성하는지 검증.
void main() {
  group('BookingNotificationService 협상 알림 (#541)', () {
    test('제안 → scheduleChangeRequested, 수신자=상대, 선생 발신 문구', () {
      final n = BookingNotificationService.createScheduleChangeProposed(
        userId: 'student1',
        fromTeacher: true,
        data: {'subscriptionId': 'sub1'},
      );
      expect(n.userId, 'student1');
      expect(n.type, NotificationType.scheduleChangeRequested);
      expect(n.title, AppStrings.scheduleChangeNotifyProposedTitle);
      expect(n.body, contains('선생님'));
      expect(n.priority, NotificationPriority.high);
      expect(n.data?['subscriptionId'], 'sub1');
    });

    test('수락 → scheduleChangeApproved', () {
      final n = BookingNotificationService.createScheduleChangeAccepted(
        userId: 'teacher1',
        fromTeacher: false,
      );
      expect(n.userId, 'teacher1');
      expect(n.type, NotificationType.scheduleChangeApproved);
      expect(n.body, contains('학생'));
    });

    test('거절 → scheduleChangeRejected, 학생 발신 문구', () {
      final n = BookingNotificationService.createScheduleChangeRejected(
        userId: 'teacher1',
        fromTeacher: false,
      );
      expect(n.type, NotificationType.scheduleChangeRejected);
      expect(n.body, contains('학생'));
      expect(n.body, contains('거절'));
    });

    test('역제안 → scheduleChangeAlternative, 확인 우선순위 high', () {
      final n = BookingNotificationService.createScheduleChangeCountered(
        userId: 'student1',
        fromTeacher: true,
      );
      expect(n.type, NotificationType.scheduleChangeAlternative);
      expect(n.title, AppStrings.scheduleChangeNotifyCounteredTitle);
      expect(n.priority, NotificationPriority.high);
    });

    test('수신자별로 userId 가 다르게 설정된다', () {
      final toStudent = BookingNotificationService.createScheduleChangeProposed(
        userId: 's1',
        fromTeacher: true,
      );
      final toTeacher = BookingNotificationService.createScheduleChangeProposed(
        userId: 't1',
        fromTeacher: false,
      );
      expect(toStudent.userId, 's1');
      expect(toTeacher.userId, 't1');
      expect(toStudent.body, isNot(equals(toTeacher.body)));
    });
  });
}
