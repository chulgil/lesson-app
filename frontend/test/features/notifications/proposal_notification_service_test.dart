// TDD test for ProposalNotificationService — Bug #726 :id literal fix.
//
// Problem: actionUrl builds as '${AppRoutes.proposalDetail}?proposalId=xxx'
// which expands to '/proposals/:id?proposalId=xxx' — the ':id' stays literal.
// GoRouter cannot match the route.
//
// Fix: replaceFirst(':id', proposalId) to get '/proposals/<realId>'.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/proposal_notification_service.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';

/// Captures the last notification passed to showNotification.
class _CapturingNotificationService implements NotificationService {
  AppNotification? last;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showNotification(AppNotification notification) async {
    last = notification;
  }

  @override
  Future<void> scheduleNotification(AppNotification notification) async {}

  @override
  Future<void> cancelNotification(String id) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Stream<AppNotification> get onNotificationTapped => const Stream.empty();
}

void main() {
  late _CapturingNotificationService capture;
  late ProposalNotificationService service;

  setUp(() {
    capture = _CapturingNotificationService();
    service = ProposalNotificationService(capture);
  });

  group('ProposalNotificationService — Bug #726 :id path param 치환', () {
    test('sendProposalReceivedNotification: actionUrl 에 :id 리터럴 없음', () async {
      const proposalId = 'prop-abc-123';

      // RED: before fix, actionUrl == '/proposals/:id?proposalId=prop-abc-123'
      // GREEN: after fix,  actionUrl == '/proposals/prop-abc-123'
      await service.sendProposalReceivedNotification(
        studentId: 'student-1',
        teacherName: '김선생님',
        proposalId: proposalId,
        templateName: '바이올린 8회',
      );

      final url = capture.last?.actionUrl;
      expect(url, isNotNull);
      expect(
        url,
        isNot(contains(':id')),
        reason: ':id 리터럴이 URL 에 남으면 GoRouter 매칭 실패',
      );
      expect(
        url,
        contains(proposalId),
        reason: '실제 proposalId 가 URL 경로에 포함되어야 함',
      );
      expect(
        url,
        equals('/proposals/$proposalId'),
        reason: 'actionUrl 은 path-only 여야 함 (query param 불필요)',
      );
    });

    test('sendProposalReminderNotification: actionUrl 에 :id 리터럴 없음', () async {
      const proposalId = 'prop-xyz-456';

      // RED before fix, GREEN after fix.
      await service.sendProposalReminderNotification(
        studentId: 'student-1',
        teacherName: '박선생님',
        proposalId: proposalId,
        hoursRemaining: 24,
      );

      final url = capture.last?.actionUrl;
      expect(url, isNotNull);
      expect(url, isNot(contains(':id')));
      expect(url, contains(proposalId));
      expect(url, equals('/proposals/$proposalId'));
    });
  });
}
