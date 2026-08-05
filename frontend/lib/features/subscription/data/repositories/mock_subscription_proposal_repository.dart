import '../../domain/entities/subscription_proposal.dart';
import '../../domain/repositories/subscription_proposal_repository.dart';

/// Mock implementation of SubscriptionProposalRepository.
class MockSubscriptionProposalRepository
    implements SubscriptionProposalRepository {
  final Map<String, SubscriptionProposal> _proposals = {};

  MockSubscriptionProposalRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // ============================================================
    // Mock 데이터 설계 원칙:
    // - 한 학생에게 하나의 pending 제안만 존재
    // - 시스템 자동 제안: 체험레슨 후 신규 학생 대상
    // - 선생님 수동 제안: 기존 학생 재등록/연장 대상
    // ============================================================

    final proposals = [
      // ============================================================
      // 🤖 시스템 자동 제안 (체험레슨 후 신규 학생)
      // ============================================================

      // student_1: 체험레슨 완료 후 시스템이 자동 발송한 제안
      // → 골든타임 할인 혜택과 함께 수강권 선택 옵션 제공
      SubscriptionProposal(
        id: 'proposal_auto_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        templateId: 'template_t1_1', // 기본 선택: 4회권
        templateIds: ['template_t1_1', 'template_t1_2', 'template_t1_3'],
        recommendedTemplateId: 'template_t1_2', // 8회권 추천
        message: null, // 시스템 제안은 개인 메시지 없음
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 71)), // 72시간 골든타임
        isAutoProposal: true,
        discountAmount: 38000,
        discountReason: '체험레슨 후 72시간 골든타임 할인 (10%)',
      ),

      // student_5: 골든타임 만료됨 (히스토리)
      SubscriptionProposal(
        id: 'proposal_auto_2',
        teacherId: 'teacher_1',
        studentId: 'student_5',
        templateId: 'template_t1_2',
        templateIds: ['template_t1_1', 'template_t1_2'],
        recommendedTemplateId: 'template_t1_2',
        message: null,
        status: ProposalStatus.expired,
        createdAt: now.subtract(const Duration(hours: 74)),
        expiresAt: now.subtract(const Duration(hours: 2)), // 이미 만료
        isAutoProposal: true,
        discountAmount: 38000,
        discountReason: '골든타임 할인 (만료됨)',
      ),

      // ============================================================
      // 👨‍🏫 선생님 수동 제안 (기존 학생 대상)
      // ============================================================

      // student_2: 수강권 만료 예정인 기존 학생에게 선생님이 직접 제안
      SubscriptionProposal(
        id: 'proposal_teacher_1',
        teacherId: 'teacher_1',
        studentId: 'student_2',
        templateId: 'template_t1_3', // 16회권
        message: '민호야, 수강권이 곧 끝나가네요!\n'
            '16회권으로 연장하면 할인 적용해드릴게요',
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 6)),
        isAutoProposal: false,
        discountAmount: 50000,
        discountReason: '장기 수강 할인',
      ),

      // student_3: 선생님이 여러 옵션 중 선택하도록 제안
      SubscriptionProposal(
        id: 'proposal_teacher_2',
        teacherId: 'teacher_1',
        studentId: 'student_3',
        templateId: 'template_t1_1',
        templateIds: ['template_t1_1', 'template_t1_2'],
        recommendedTemplateId: 'template_t1_2',
        message: '서연아, 다음 달부터 레슨 시작해볼까요?\n'
            '선생님은 8회권 추천해요',
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(days: 7)),
        isAutoProposal: false,
      ),

      // ============================================================
      // 진행 중인 상태 샘플 (다른 학생들)
      // ============================================================

      // student_4: 입금 완료 알림 후 선생님 확인 대기 중
      SubscriptionProposal(
        id: 'proposal_paid_1',
        teacherId: 'teacher_1',
        studentId: 'student_4',
        templateId: 'template_t1_1',
        message: null,
        status: ProposalStatus.paymentNotified,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 5)),
        paymentNotifiedAt: now.subtract(const Duration(hours: 3)),
        isAutoProposal: true,
      ),

      // student_6: 수강권 발급 완료 (히스토리)
      SubscriptionProposal(
        id: 'proposal_confirmed_1',
        teacherId: 'teacher_1',
        studentId: 'student_6',
        templateId: 'template_t1_2',
        message: '열심히 해봐요!',
        status: ProposalStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 5)),
        expiresAt: now.add(const Duration(days: 2)),
        paymentNotifiedAt: now.subtract(const Duration(days: 4)),
        confirmedAt: now.subtract(const Duration(days: 4)),
        subscriptionId: 'sub_paused_01',
        isAutoProposal: false,
      ),

      // student_7: 스킵된 제안 (히스토리)
      SubscriptionProposal(
        id: 'proposal_rejected_1',
        teacherId: 'teacher_1',
        studentId: 'student_7',
        templateId: 'template_t1_3',
        message: null,
        status: ProposalStatus.rejected,
        createdAt: now.subtract(const Duration(days: 3)),
        expiresAt: now.add(const Duration(days: 4)),
        rejectedAt: now.subtract(const Duration(days: 2)),
        rejectionReason: '일정이 맞지 않아서요',
        isAutoProposal: true,
      ),

      // ============================================================
      // 🔄 갱신 제안 (Renewal Proposals)
      // ============================================================

      // student_5: 수강권 1회 남음 → 시스템 자동 갱신 제안
      SubscriptionProposal(
        id: 'proposal_renewal_1',
        teacherId: 'teacher_1',
        studentId: 'student_5',
        templateId: 'template_t1_1',
        templateIds: ['template_t1_1', 'template_t1_2'],
        recommendedTemplateId: 'template_t1_1',
        message: '수강권이 1회 남았습니다. 이전과 동일한 수강권으로 레슨을 이어가세요.',
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(days: 7)),
        isAutoProposal: true,
        isRenewal: true,
        previousSubscriptionId: 'sub_pkg_03',
        renewalInitiator: RenewalInitiator.system,
      ),

      // student_9: 수강권 만료 → 선생님 수동 갱신 제안
      SubscriptionProposal(
        id: 'proposal_renewal_2',
        teacherId: 'teacher_1',
        studentId: 'student_9',
        templateId: 'template_t1_2',
        message: '지민아, 수강권이 만료되었네요!\n같은 조건으로 이어서 레슨하면 좋겠어요',
        status: ProposalStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 6)),
        isAutoProposal: false,
        isRenewal: true,
        previousSubscriptionId: 'sub_exp_02',
        renewalInitiator: RenewalInitiator.teacher,
      ),
    ];

    for (final proposal in proposals) {
      _proposals[proposal.id] = proposal;
    }
  }

  @override
  Future<List<SubscriptionProposal>> getByTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _proposals.values
        .where((p) => p.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<SubscriptionProposal>> getByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _proposals.values
        .where((p) => p.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<SubscriptionProposal>> getActiveByTeacher(
      String teacherId) async {
    final proposals = await getByTeacher(teacherId);
    return proposals.where((p) => p.isActive).toList();
  }

  @override
  Future<List<SubscriptionProposal>> getActiveByStudent(
      String studentId) async {
    final proposals = await getByStudent(studentId);
    return proposals.where((p) => p.isActive).toList();
  }

  @override
  Future<List<SubscriptionProposal>> getPendingByStudent(
      String studentId) async {
    final proposals = await getByStudent(studentId);
    return proposals
        .where((p) => p.status == ProposalStatus.pending && !p.isExpired)
        .toList();
  }

  @override
  Future<List<SubscriptionProposal>> getAwaitingConfirmation(
      String teacherId) async {
    final proposals = await getByTeacher(teacherId);
    return proposals
        .where(
            (p) => p.status == ProposalStatus.paymentNotified && !p.isExpired)
        .toList();
  }

  @override
  Future<SubscriptionProposal?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _proposals[id];
  }

  @override
  Future<SubscriptionProposal> create(SubscriptionProposal proposal) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Generate ID if not provided
    final newProposal = proposal.id.isEmpty
        ? proposal.copyWith(
            id: 'proposal_${DateTime.now().millisecondsSinceEpoch}',
          )
        : proposal;

    _proposals[newProposal.id] = newProposal;
    return newProposal;
  }

  @override
  Future<SubscriptionProposal> notifyPayment(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final proposal = _proposals[id];
    if (proposal == null) {
      throw Exception('Proposal not found: $id');
    }
    if (proposal.status != ProposalStatus.pending) {
      throw Exception('Cannot notify payment for proposal with status: ${proposal.status}');
    }

    final updated = proposal.copyWith(
      status: ProposalStatus.paymentNotified,
      paymentNotifiedAt: DateTime.now(),
    );
    _proposals[id] = updated;
    return updated;
  }

  @override
  Future<SubscriptionProposal> confirmPayment(
      String id, String subscriptionId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final proposal = _proposals[id];
    if (proposal == null) {
      throw Exception('Proposal not found: $id');
    }
    if (proposal.status != ProposalStatus.paymentNotified) {
      throw Exception('Cannot confirm payment for proposal with status: ${proposal.status}');
    }

    final updated = proposal.copyWith(
      status: ProposalStatus.confirmed,
      confirmedAt: DateTime.now(),
      subscriptionId: subscriptionId,
    );
    _proposals[id] = updated;
    return updated;
  }

  @override
  Future<SubscriptionProposal> reject(String id, String? reason) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final proposal = _proposals[id];
    if (proposal == null) {
      throw Exception('Proposal not found: $id');
    }
    if (!proposal.status.isActive) {
      throw Exception('Cannot reject proposal with status: ${proposal.status}');
    }

    final updated = proposal.copyWith(
      status: ProposalStatus.rejected,
      rejectedAt: DateTime.now(),
      rejectionReason: reason,
    );
    _proposals[id] = updated;
    return updated;
  }

  @override
  Future<SubscriptionProposal> cancel(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final proposal = _proposals[id];
    if (proposal == null) {
      throw Exception('Proposal not found: $id');
    }
    if (!proposal.status.isActive) {
      throw Exception('Cannot cancel proposal with status: ${proposal.status}');
    }

    final updated = proposal.copyWith(
      status: ProposalStatus.cancelled,
    );
    _proposals[id] = updated;
    return updated;
  }

  @override
  Future<void> expireOldProposals() async {
    await Future.delayed(const Duration(milliseconds: 50));

    final now = DateTime.now();
    for (final entry in _proposals.entries) {
      final proposal = entry.value;
      if (proposal.status.isActive && proposal.expiresAt.isBefore(now)) {
        _proposals[entry.key] = proposal.copyWith(
          status: ProposalStatus.expired,
        );
      }
    }
  }

  @override
  Future<SubscriptionProposal?> getActiveProposal(
      String teacherId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      return _proposals.values.firstWhere(
        (p) =>
            p.teacherId == teacherId &&
            p.studentId == studentId &&
            p.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SubscriptionProposal> selectTemplate(
      String id, String templateId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final proposal = _proposals[id];
    if (proposal == null) {
      throw Exception('Proposal not found: $id');
    }
    if (proposal.status != ProposalStatus.pending) {
      throw Exception(
          'Cannot select template for proposal with status: ${proposal.status}');
    }

    // Verify templateId is in the allowed list
    if (proposal.isMultiChoice &&
        !proposal.allTemplateIds.contains(templateId)) {
      throw Exception('Template $templateId is not in the proposal options');
    }

    final updated = proposal.copyWith(
      selectedTemplateId: templateId,
    );
    _proposals[id] = updated;
    return updated;
  }
}
