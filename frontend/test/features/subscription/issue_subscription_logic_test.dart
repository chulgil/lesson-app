import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_actions.dart';

void main() {
  group('addMonthsClamped (monthly end date — month-end overflow)', () {
    test('Jan 31 + 1 month clamps to Feb 28 (non-leap year), not Mar', () {
      final result = addMonthsClamped(DateTime(2026, 1, 31), 1);
      expect(result, DateTime(2026, 2, 28));
    });

    test('Jan 31 + 1 month clamps to Feb 29 in a leap year', () {
      final result = addMonthsClamped(DateTime(2028, 1, 31), 1);
      expect(result, DateTime(2028, 2, 29));
    });

    test('rolls the year over when crossing December', () {
      final result = addMonthsClamped(DateTime(2026, 11, 30), 3);
      expect(result, DateTime(2027, 2, 28));
    });

    test('preserves day when it exists in the target month', () {
      final result = addMonthsClamped(DateTime(2026, 3, 15), 6);
      expect(result, DateTime(2026, 9, 15));
    });

    test('preserves time-of-day components', () {
      final result =
          addMonthsClamped(DateTime(2026, 1, 31, 14, 30, 15), 1);
      expect(result, DateTime(2026, 2, 28, 14, 30, 15));
    });
  });

  group('monthly subscription lessonsPerMonth → remaining/display', () {
    test('remainingLessons uses lessonsPerMonth (not null) for monthly', () {
      final sub = Subscription(
        id: 's1',
        studentId: 'st1',
        membershipId: 'm1',
        type: SubscriptionType.monthly,
        lessonsPerMonth: 4,
        usedLessons: 1,
        amount: 100000,
        status: SubscriptionStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(sub.lessonsPerMonth, 4);
      expect(sub.remainingLessons, 3);
      expect(sub.totalLessonsForDisplay, 4);
    });

    test('monthly without lessonsPerMonth yields null remaining (the bug)', () {
      final sub = Subscription(
        id: 's2',
        studentId: 'st1',
        membershipId: 'm1',
        type: SubscriptionType.monthly,
        usedLessons: 0,
        amount: 100000,
        status: SubscriptionStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(sub.remainingLessons, isNull);
    });
  });

  group('proposal effectiveTemplateId (multi-choice selection)', () {
    SubscriptionProposal base({
      List<String> templateIds = const [],
      String? selectedTemplateId,
    }) {
      return SubscriptionProposal(
        id: 'p1',
        teacherId: 't1',
        studentId: 'st1',
        templateId: 'base-template',
        templateIds: templateIds,
        selectedTemplateId: selectedTemplateId,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime(2026, 1, 8),
      );
    }

    test('single-choice uses base templateId', () {
      expect(base().effectiveTemplateId, 'base-template');
    });

    test('multi-choice with selection uses the selected template', () {
      final p = base(
        templateIds: ['a', 'b', 'c'],
        selectedTemplateId: 'b',
      );
      expect(p.effectiveTemplateId, 'b');
      expect(p.needsTemplateSelection, isFalse);
    });

    test('multi-choice without selection needs selection', () {
      final p = base(templateIds: ['a', 'b']);
      expect(p.needsTemplateSelection, isTrue);
      // Falls back to first option for display, but the confirm guard relies
      // on needsTemplateSelection to block issuance.
      expect(p.effectiveTemplateId, 'a');
    });
  });
}
