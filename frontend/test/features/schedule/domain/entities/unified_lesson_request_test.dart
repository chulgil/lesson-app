import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helper
  // ═══════════════════════════════════════════════════════════════════════════

  UnifiedLessonRequest createRequest({
    UnifiedRequestStatus status = UnifiedRequestStatus.pending,
    String? proposalId,
  }) {
    return UnifiedLessonRequest(
      id: 'req_1',
      studentId: 'student_1',
      teacherId: 'teacher_1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      status: status,
      createdAt: DateTime(2026, 3, 1),
      proposalId: proposalId,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // proposalId field
  // ═══════════════════════════════════════════════════════════════════════════

  group('proposalId', () {
    test('기본값 null', () {
      final request = createRequest();
      expect(request.proposalId, isNull);
    });

    test('값 설정', () {
      final request = createRequest(proposalId: 'proposal_1');
      expect(request.proposalId, 'proposal_1');
    });

    test('copyWith로 proposalId 설정', () {
      final request = createRequest();
      final updated = request.copyWith(proposalId: 'proposal_2');
      expect(updated.proposalId, 'proposal_2');
      expect(request.proposalId, isNull); // immutability
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // canTransitionTo tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('canTransitionTo', () {
    test('timeConfirmed → proposalSent (유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.timeConfirmed);
      expect(request.canTransitionTo(UnifiedRequestStatus.proposalSent), isTrue);
    });

    test('timeConfirmed → completed (체험 무료 경로, 유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.timeConfirmed);
      expect(request.canTransitionTo(UnifiedRequestStatus.completed), isTrue);
    });

    test('proposalSent → proposalAccepted (유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.proposalSent);
      expect(request.canTransitionTo(UnifiedRequestStatus.proposalAccepted), isTrue);
    });

    test('proposalAccepted → paymentNotified (유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.proposalAccepted);
      expect(request.canTransitionTo(UnifiedRequestStatus.paymentNotified), isTrue);
    });

    test('paymentNotified → completed (유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.paymentNotified);
      expect(request.canTransitionTo(UnifiedRequestStatus.completed), isTrue);
    });

    test('pending → proposalSent (무효 — 시간 확정 건너뜀)', () {
      final request = createRequest(status: UnifiedRequestStatus.pending);
      expect(request.canTransitionTo(UnifiedRequestStatus.proposalSent), isFalse);
    });

    test('completed → pending (무효 — 터미널에서 되돌리기)', () {
      final request = createRequest(status: UnifiedRequestStatus.completed);
      expect(request.canTransitionTo(UnifiedRequestStatus.pending), isFalse);
    });

    test('any → cancelled (항상 유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.proposalSent);
      expect(request.canTransitionTo(UnifiedRequestStatus.cancelled), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // convenience getters
  // ═══════════════════════════════════════════════════════════════════════════

  group('convenience getters', () {
    test('isWaitingForProposal — timeConfirmed', () {
      final request = createRequest(status: UnifiedRequestStatus.timeConfirmed);
      expect(request.isWaitingForProposal, isTrue);
    });

    test('isWaitingForProposal — pending', () {
      final request = createRequest(status: UnifiedRequestStatus.pending);
      expect(request.isWaitingForProposal, isFalse);
    });

    test('isProposalReceived — proposalSent', () {
      final request = createRequest(status: UnifiedRequestStatus.proposalSent);
      expect(request.isProposalReceived, isTrue);
    });

    test('isProposalReceived — paymentNotified', () {
      final request = createRequest(status: UnifiedRequestStatus.paymentNotified);
      expect(request.isProposalReceived, isFalse);
    });

    test('isPaymentPending — proposalAccepted or paymentNotified', () {
      expect(
        createRequest(status: UnifiedRequestStatus.proposalAccepted).isPaymentPending,
        isTrue,
      );
      expect(
        createRequest(status: UnifiedRequestStatus.paymentNotified).isPaymentPending,
        isTrue,
      );
      expect(
        createRequest(status: UnifiedRequestStatus.proposalSent).isPaymentPending,
        isFalse,
      );
    });

    test('hasProposal — proposalId 존재 여부', () {
      expect(createRequest(proposalId: 'p1').hasProposal, isTrue);
      expect(createRequest(proposalId: null).hasProposal, isFalse);
    });
  });
}
