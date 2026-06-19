import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/data/repositories/payment_inquiry_storage.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_proposal_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/payment_inquiry_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/proposal_confirm_screen.dart';

/// Spy subscription repo — records every `create` so the test can prove the
/// batch flow persists exactly one subscription per selected proposal, and the
/// created subscriptions carry confirmed payment fields.
class _RecordingSubscriptionRepository extends MockSubscriptionRepository {
  final List<Subscription> created = [];

  @override
  Future<Subscription> create(Subscription subscription) async {
    final result = await super.create(subscription);
    created.add(result);
    return result;
  }
}

/// Fake proposal repo returning two real-seed-backed awaiting proposals (so the
/// per-card student/template providers resolve against the real mocks) and
/// recording which proposals get `confirmPayment`-ed during a batch.
class _FakeProposalRepository implements SubscriptionProposalRepository {
  _FakeProposalRepository(this._proposals);

  final List<SubscriptionProposal> _proposals;
  final List<String> confirmedIds = [];

  @override
  Future<List<SubscriptionProposal>> getAwaitingConfirmation(
    String teacherId,
  ) async {
    return _proposals
        .where((p) => p.status == ProposalStatus.paymentNotified)
        .toList();
  }

  @override
  Future<SubscriptionProposal> confirmPayment(
    String id,
    String subscriptionId,
  ) async {
    confirmedIds.add(id);
    final p = _proposals.firstWhere((p) => p.id == id);
    return p.copyWith(
      status: ProposalStatus.confirmed,
      subscriptionId: subscriptionId,
      confirmedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// In-memory inquiry storage — keeps the screen's hold-memo provider off Hive
/// (uninitialised in widget tests).
class _FakeInquiryStorage extends PaymentInquiryStorage {
  @override
  Future<void> recordInquiry(String userId, String proposalId) async {}

  @override
  Future<Map<String, DateTime>> loadAll(String userId) async => const {};

  @override
  Future<void> clear(String userId, String proposalId) async {}
}

SubscriptionProposal _awaiting(String id, String studentId, String templateId) {
  final now = DateTime(2026, 1, 1);
  return SubscriptionProposal(
    id: id,
    teacherId: 'teacher_1',
    studentId: studentId,
    templateId: templateId,
    status: ProposalStatus.paymentNotified,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
    paymentNotifiedAt: now,
  );
}

Future<void> _pumpN(WidgetTester tester, {int n = 30}) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('batch confirm issues one subscription per selected proposal', (
    tester,
  ) async {
    final subRepo = _RecordingSubscriptionRepository();
    // Real seeded student + template ids so the cards resolve against the
    // real mock student / template repositories.
    final proposalRepo = _FakeProposalRepository([
      _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
      _awaiting('proposal_batch_2', 'student_6', 'template_t1_2'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(subRepo),
          subscriptionProposalRepositoryProvider.overrideWithValue(
            proposalRepo,
          ),
          paymentInquiryStorageProvider.overrideWithValue(
            _FakeInquiryStorage(),
          ),
        ],
        child: const MaterialApp(
          home: ProposalConfirmScreen(teacherId: 'teacher_1'),
        ),
      ),
    );
    await _pumpN(tester);

    // Two awaiting cards → two selection checkboxes.
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(2));

    await tester.tap(checkboxes.at(0));
    await tester.tap(checkboxes.at(1));
    await _pumpN(tester, n: 6);

    // Batch action bar appears once ≥1 selected.
    final batchButton = find.text(AppStrings.paymentBatchConfirmAction(2));
    expect(batchButton, findsOneWidget);
    await tester.tap(batchButton);
    await _pumpN(tester, n: 6);

    // Confirm dialog (money / impact action gate).
    final dialogConfirm = find.text(AppStrings.paymentBatchIssueConfirm);
    expect(dialogConfirm, findsOneWidget);
    await tester.tap(dialogConfirm);
    await _pumpN(tester);

    expect(
      subRepo.created.length,
      2,
      reason: 'one subscription persisted per selected proposal',
    );
    expect(
      proposalRepo.confirmedIds.length,
      2,
      reason: 'each selected proposal must be confirmed',
    );
    expect(
      subRepo.created.every((s) => s.paymentConfirmed),
      isTrue,
      reason: 'batch-issued subscriptions carry confirmed payment',
    );
  });

  testWidgets('cards render without overflow at narrow (375) width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final subRepo = _RecordingSubscriptionRepository();
    final proposalRepo = _FakeProposalRepository([
      _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
      _awaiting('proposal_batch_2', 'student_6', 'template_t1_2'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(subRepo),
          subscriptionProposalRepositoryProvider.overrideWithValue(
            proposalRepo,
          ),
          paymentInquiryStorageProvider.overrideWithValue(
            _FakeInquiryStorage(),
          ),
        ],
        child: const MaterialApp(
          home: ProposalConfirmScreen(teacherId: 'teacher_1'),
        ),
      ),
    );
    await _pumpN(tester);

    expect(find.byType(Checkbox), findsNWidgets(2));

    // Selecting reveals the batch bar — still no layout overflow at 375.
    await tester.tap(find.byType(Checkbox).first);
    await _pumpN(tester, n: 6);
    expect(find.text(AppStrings.paymentBatchConfirmAction(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
