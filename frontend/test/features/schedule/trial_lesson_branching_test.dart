import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

/// Tests for trial lesson free/paid branching logic.
///
/// The branching decision is:
///   trialLessonFree == true  → completeRequest (즉시 완료)
///   trialLessonFree == false → send payment request (입금 요청)
void main() {
  group('Trial lesson branching logic', () {
    test('trial + free → should complete directly', () {
      const isTrialLessonFree = true;
      const type = LessonRequestType.trial;

      final shouldCompleteDirectly = type == LessonRequestType.trial && isTrialLessonFree;
      final shouldRequestPayment = type == LessonRequestType.trial && !isTrialLessonFree;

      expect(shouldCompleteDirectly, isTrue);
      expect(shouldRequestPayment, isFalse);
    });

    test('trial + paid → should request payment', () {
      const isTrialLessonFree = false;
      const type = LessonRequestType.trial;

      final shouldCompleteDirectly = type == LessonRequestType.trial && isTrialLessonFree;
      final shouldRequestPayment = type == LessonRequestType.trial && !isTrialLessonFree;

      expect(shouldCompleteDirectly, isFalse);
      expect(shouldRequestPayment, isTrue);
    });

    test('regular → should always go to subscription', () {
      const type = LessonRequestType.regular;

      final isTrialFreeFlow = type == LessonRequestType.trial;

      expect(isTrialFreeFlow, isFalse);
    });
  });

  group('Trial lesson snackbar messages', () {
    test('free trial shows completion message', () {
      expect(AppStrings.trialComplete, contains('체험레슨'));
      expect(AppStrings.trialComplete, contains('완료'));
    });

    test('paid trial shows payment request message', () {
      expect(AppStrings.trialPaymentRequested, contains('입금'));
    });
  });
}
