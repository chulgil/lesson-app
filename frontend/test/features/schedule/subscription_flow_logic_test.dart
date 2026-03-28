import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/subscription/domain/services/subscription_flow_helper.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  TeacherSettings createSettings({
    bool trialFree = false,
    Map<String, Map<String, int>>? priceTable,
  }) {
    return TeacherSettings(
      id: 'teacher_1',
      instruments: ['바이올린'],
      createdAt: DateTime(2026, 1, 1),
      trialLessonFree: trialFree,
      lessonPriceTable: priceTable,
    );
  }

  UnifiedLessonRequest createRequest({
    LessonRequestType type = LessonRequestType.regular,
    String instrument = '바이올린',
    UnifiedExperienceLevel experience = UnifiedExperienceLevel.beginner,
    UnifiedRequestStatus status = UnifiedRequestStatus.timeConfirmed,
  }) {
    return UnifiedLessonRequest(
      id: 'req_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      type: type,
      instrument: instrument,
      goal: UnifiedLessonGoal.hobby,
      experience: experience,
      status: status,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // shouldAutoComplete tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('shouldAutoComplete', () {
    test('trial + free → true (수강권 없이 즉시 완료)', () {
      final request = createRequest(type: LessonRequestType.trial);
      final settings = createSettings(trialFree: true);

      expect(SubscriptionFlowHelper.shouldAutoComplete(request, settings), isTrue);
    });

    test('trial + paid → false (수강권 필요)', () {
      final request = createRequest(type: LessonRequestType.trial);
      final settings = createSettings(trialFree: false);

      expect(SubscriptionFlowHelper.shouldAutoComplete(request, settings), isFalse);
    });

    test('regular → false (항상 수강권 필요)', () {
      final request = createRequest(type: LessonRequestType.regular);
      final settings = createSettings(trialFree: true);

      expect(SubscriptionFlowHelper.shouldAutoComplete(request, settings), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // shouldSendProposal tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('shouldSendProposal', () {
    test('regular → true', () {
      final request = createRequest(type: LessonRequestType.regular);
      final settings = createSettings();

      expect(SubscriptionFlowHelper.shouldSendProposal(request, settings), isTrue);
    });

    test('trial + paid → true', () {
      final request = createRequest(type: LessonRequestType.trial);
      final settings = createSettings(trialFree: false);

      expect(SubscriptionFlowHelper.shouldSendProposal(request, settings), isTrue);
    });

    test('trial + free → false', () {
      final request = createRequest(type: LessonRequestType.trial);
      final settings = createSettings(trialFree: true);

      expect(SubscriptionFlowHelper.shouldSendProposal(request, settings), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // suggestedPriceForRequest tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('suggestedPriceForRequest', () {
    test('가격표에서 instrument × experience 매칭 → 가격 반환', () {
      final request = createRequest(
        instrument: '바이올린',
        experience: UnifiedExperienceLevel.intermediate,
      );
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000, 'intermediate': 50000, 'advanced': 70000},
        },
      );

      expect(
        SubscriptionFlowHelper.suggestedPriceForRequest(request, settings),
        50000,
      );
    });

    test('가격표 없음 → null', () {
      final request = createRequest();
      final settings = createSettings(priceTable: null);

      expect(
        SubscriptionFlowHelper.suggestedPriceForRequest(request, settings),
        isNull,
      );
    });

    test('악기 미등록 → null', () {
      final request = createRequest(instrument: '첼로');
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000},
        },
      );

      expect(
        SubscriptionFlowHelper.suggestedPriceForRequest(request, settings),
        isNull,
      );
    });

    test('체험(무료) → 0', () {
      final request = createRequest(type: LessonRequestType.trial);
      final settings = createSettings(trialFree: true);

      expect(
        SubscriptionFlowHelper.suggestedPriceForRequest(request, settings),
        0,
      );
    });
  });
}
