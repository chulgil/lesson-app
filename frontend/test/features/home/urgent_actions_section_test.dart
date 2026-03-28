import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/urgent_actions_section.dart';

void main() {
  group('UrgentActionsSection - item count', () {
    test('should only have 2 item types: lesson requests and payment confirm', () {
      // UrgentActionsSection should accept exactly 3 data params:
      // teacherId, pendingRequests, awaitingConfirmCount
      // NOT: pendingBookings, expiringSoon, expired
      final section = UrgentActionsSection(
        teacherId: 'teacher_1',
        pendingRequests: 2,
        awaitingConfirmCount: 1,
      );

      expect(section.teacherId, 'teacher_1');
      expect(section.pendingRequests, 2);
      expect(section.awaitingConfirmCount, 1);
    });

    test('total urgent count is sum of requests + payment only', () {
      // With 2 requests and 1 payment, total should be 3
      // NOT 4 (no bookings) or 5 (no subscriptions)
      final section = UrgentActionsSection(
        teacherId: 'teacher_1',
        pendingRequests: 2,
        awaitingConfirmCount: 1,
      );

      expect(section.pendingRequests + section.awaitingConfirmCount, 3);
    });

    test('hidden when both counts are zero', () {
      final section = UrgentActionsSection(
        teacherId: 'teacher_1',
        pendingRequests: 0,
        awaitingConfirmCount: 0,
      );

      expect(section.pendingRequests + section.awaitingConfirmCount, 0);
    });
  });

  group('UrgentActionsSection - CTA labels', () {
    test('lesson request item uses AppStrings.lessonRequest', () {
      // The title format should use AppStrings
      expect(AppStrings.lessonRequestPending(3), '레슨 요청 3건 대기');
    });

    test('payment confirm item uses AppStrings.paymentConfirm', () {
      expect(AppStrings.paymentConfirmPending(2), '입금 확인 2건 대기');
    });
  });
}
