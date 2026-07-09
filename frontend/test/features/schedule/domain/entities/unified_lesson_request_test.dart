import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/unified_lesson_request_visuals.dart';

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
      expect(
        request.canTransitionTo(UnifiedRequestStatus.proposalSent),
        isTrue,
      );
    });

    test('timeConfirmed → completed (체험 무료 경로, 유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.timeConfirmed);
      expect(request.canTransitionTo(UnifiedRequestStatus.completed), isTrue);
    });

    test('proposalSent → proposalAccepted (유효)', () {
      final request = createRequest(status: UnifiedRequestStatus.proposalSent);
      expect(
        request.canTransitionTo(UnifiedRequestStatus.proposalAccepted),
        isTrue,
      );
    });

    test('proposalAccepted → paymentNotified (유효)', () {
      final request = createRequest(
        status: UnifiedRequestStatus.proposalAccepted,
      );
      expect(
        request.canTransitionTo(UnifiedRequestStatus.paymentNotified),
        isTrue,
      );
    });

    test('paymentNotified → subscriptionIssued (입금 확인 후 수강권 발급, 유효)', () {
      final request = createRequest(
        status: UnifiedRequestStatus.paymentNotified,
      );
      expect(
        request.canTransitionTo(UnifiedRequestStatus.subscriptionIssued),
        isTrue,
      );
      expect(request.canTransitionTo(UnifiedRequestStatus.completed), isFalse);
    });

    test('pending → proposalSent (무효 — 시간 확정 건너뜀)', () {
      final request = createRequest(status: UnifiedRequestStatus.pending);
      expect(
        request.canTransitionTo(UnifiedRequestStatus.proposalSent),
        isFalse,
      );
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
      final request = createRequest(
        status: UnifiedRequestStatus.paymentNotified,
      );
      expect(request.isProposalReceived, isFalse);
    });

    test('isPaymentPending — proposalAccepted or paymentNotified', () {
      expect(
        createRequest(
          status: UnifiedRequestStatus.proposalAccepted,
        ).isPaymentPending,
        isTrue,
      );
      expect(
        createRequest(
          status: UnifiedRequestStatus.paymentNotified,
        ).isPaymentPending,
        isTrue,
      );
      expect(
        createRequest(
          status: UnifiedRequestStatus.proposalSent,
        ).isPaymentPending,
        isFalse,
      );
    });

    test('hasProposal — proposalId 존재 여부', () {
      expect(createRequest(proposalId: 'p1').hasProposal, isTrue);
      expect(createRequest(proposalId: null).hasProposal, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // v4.0: package type + academyId + events
  // ═══════════════════════════════════════════════════════════════════════════

  group('LessonRequestType', () {
    test('package 타입 존재', () {
      expect(LessonRequestType.package.label, '회차권');
    });

    test('3가지 타입', () {
      expect(LessonRequestType.values.length, 3);
    });
  });

  group('academyId', () {
    test('기본값 null — 개인', () {
      final request = createRequest();
      expect(request.academyId, isNull);
      expect(request.isAcademy, isFalse);
    });

    test('학원 소속', () {
      final request = createRequest().copyWith(academyId: 'academy_1');
      expect(request.academyId, 'academy_1');
      expect(request.isAcademy, isTrue);
    });
  });

  group('7일 만료', () {
    test('생성 후 6일 — 미만료', () {
      final request = UnifiedLessonRequest(
        id: 'req_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        status: UnifiedRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      );
      expect(request.isExpiredByDate, isFalse);
    });

    test('생성 후 8일 — 만료', () {
      final request = UnifiedLessonRequest(
        id: 'req_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        status: UnifiedRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(request.isExpiredByDate, isTrue);
    });
  });

  group('lastMessage', () {
    test('이벤트 없으면 null', () {
      final request = createRequest();
      expect(request.lastMessage, isNull);
    });
  });

  group('statusChipLabel', () {
    test('협상 중 — 라운드 표시', () {
      final request = createRequest(
        status: UnifiedRequestStatus.negotiating,
      ).copyWith(currentRound: 3);
      expect(request.statusChipLabel, '시간 조율 중 (3회차)');
    });

    test('완료', () {
      final request = createRequest(status: UnifiedRequestStatus.completed);
      expect(request.statusChipLabel, '완료');
    });

    test('취소(학생)', () {
      final request = createRequest(status: UnifiedRequestStatus.cancelled);
      expect(request.statusChipLabel, '취소');
    });

    test('대기', () {
      final request = createRequest(status: UnifiedRequestStatus.pending);
      expect(request.statusChipLabel, '대기');
    });

    test('입금완료', () {
      final request = createRequest(
        status: UnifiedRequestStatus.paymentNotified,
      );
      expect(request.statusChipLabel, '입금완료');
    });

    test('기간만료', () {
      final request = createRequest(status: UnifiedRequestStatus.expired);
      expect(request.statusChipLabel, '기간만료');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // C2: display name resolution (entity-first, name-map fallback)
  // ═══════════════════════════════════════════════════════════════════════════

  group('display names (studentName/teacherName/academyName)', () {
    // Mirrors studentNameMap/teacherNameMap/academyNameMap mock providers.
    const studentNames = {'student_1': '김민준'};
    const teacherNames = {'teacher_1': '김선아'};
    const academyNames = {'academy_1': '서울음악학원'};

    test('fromJson 이 BE 필드(student_name/teacher_name/academy_name)를 파싱', () {
      final request = UnifiedLessonRequest.fromJson({
        'id': 'req_1',
        'student_id': 'student_999',
        'teacher_id': 'teacher_999',
        'type': 'regular',
        'instrument': '바이올린',
        'goal': 'hobby',
        'experience': 'beginner',
        'status': 'pending',
        'created_at': '2026-03-01T00:00:00.000',
        'student_name': '실제학생',
        'teacher_name': '실제선생님',
        'academy_name': '실제학원',
      });
      expect(request.studentName, '실제학생');
      expect(request.teacherName, '실제선생님');
      expect(request.academyName, '실제학원');
    });

    test('기본값 null (mock 시나리오 — 이름 미탑재)', () {
      final request = createRequest();
      expect(request.studentName, isNull);
      expect(request.teacherName, isNull);
      expect(request.academyName, isNull);
    });

    test('remote: id 가 map 에 없어도 entity 이름으로 해소 (entity-first)', () {
      final request = createRequest().copyWith(
        studentId: 'unknown_id',
        teacherId: 'unknown_id',
        academyId: 'unknown_id',
        studentName: '실제학생',
        teacherName: '실제선생님',
        academyName: '실제학원',
      );
      // resolver mirrors consumers: request.X ?? nameMap[id] ?? fallback
      expect(
        request.studentName ?? studentNames[request.studentId] ?? '학생',
        '실제학생',
      );
      expect(request.teacherName ?? teacherNames[request.teacherId], '실제선생님');
      expect(request.academyName ?? academyNames[request.academyId], '실제학원');
    });

    test('mock: entity 이름 null 이면 name map 으로 폴백', () {
      final request = createRequest(); // studentId='student_1', names null
      expect(
        request.studentName ?? studentNames[request.studentId] ?? '학생',
        '김민준',
      );
    });

    test('entity 이름·map 모두 없으면 기본값으로 폴백', () {
      final request = createRequest().copyWith(studentId: 'ghost');
      expect(
        request.studentName ?? studentNames[request.studentId] ?? '학생',
        '학생',
      );
    });
  });

  group('typeDisplayLabel', () {
    test('재수강 우선', () {
      final request = createRequest().copyWith(isReturningStudent: true);
      expect(request.typeDisplayLabel, '재수강');
    });

    test('정규레슨', () {
      final request = createRequest();
      expect(request.typeDisplayLabel, '정규레슨');
    });

    test('회차권', () {
      final request = UnifiedLessonRequest(
        id: 'req_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        type: LessonRequestType.package,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        status: UnifiedRequestStatus.pending,
        createdAt: DateTime(2026, 3, 1),
      );
      expect(request.typeDisplayLabel, '회차권');
    });
  });
}
