import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/payment_inquiry_storage.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_proposal_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/payment_inquiry_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/proposal_confirm_screen.dart';

/// In-memory inquiry storage — avoids Hive, captures recorded inquiries.
class _FakeInquiryStorage extends PaymentInquiryStorage {
  final Map<String, DateTime> store = {};

  @override
  Future<void> recordInquiry(String userId, String proposalId) async {
    store[proposalId] = DateTime(2026, 1, 1, 12);
  }

  @override
  Future<Map<String, DateTime>> loadAll(String userId) async => Map.of(store);

  @override
  Future<void> clear(String userId, String proposalId) async {
    store.remove(proposalId);
  }
}

/// Two awaiting proposals backed by real seeded student/template ids so the
/// cards resolve against the real mock repositories.
class _FakeProposalRepository implements SubscriptionProposalRepository {
  _FakeProposalRepository(this._proposals);

  final List<SubscriptionProposal> _proposals;

  @override
  Future<List<SubscriptionProposal>> getAwaitingConfirmation(
    String teacherId,
  ) async => List.of(_proposals);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeProposalRepository proposalRepo,
  required _FakeInquiryStorage storage,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProposalRepositoryProvider.overrideWithValue(proposalRepo),
        paymentInquiryStorageProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        home: ProposalConfirmScreen(teacherId: 'teacher_1'),
      ),
    ),
  );
  await _pumpN(tester);
}

void main() {
  testWidgets('tapping 입금 미확인 marks the proposal 확인 보류 (badge + filter)', (
    tester,
  ) async {
    final storage = _FakeInquiryStorage();
    final proposalRepo = _FakeProposalRepository([
      _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
      _awaiting('proposal_batch_2', 'student_6', 'template_t1_2'),
    ]);

    await _pumpScreen(tester, proposalRepo: proposalRepo, storage: storage);

    // Two inquiry buttons, no hold badge yet.
    final inquiryButtons = find.widgetWithText(
      OutlinedButton,
      AppStrings.paymentUnverifiedAction,
    );
    expect(inquiryButtons, findsNWidgets(2));
    expect(find.text(AppStrings.paymentHoldBadge), findsNothing);

    // Mark the first proposal "입금 미확인" → confirm the inquiry dialog.
    await tester.tap(inquiryButtons.first);
    await _pumpN(tester, n: 6);
    await tester.tap(find.text(AppStrings.sendMessage));
    await _pumpN(tester);

    // Recorded locally + 확인 보류 badge on exactly one card + hold chip.
    expect(storage.store.containsKey('proposal_batch_1'), isTrue);
    expect(find.text(AppStrings.paymentHoldBadge), findsOneWidget);
    expect(find.text(AppStrings.paymentFilterHoldCount(1)), findsOneWidget);

    // Filter to held only → just the one card remains.
    await tester.tap(find.text(AppStrings.paymentFilterHoldCount(1)));
    await _pumpN(tester, n: 6);
    expect(
      find.widgetWithText(OutlinedButton, AppStrings.paymentUnverifiedAction),
      findsOneWidget,
    );
  });

  testWidgets(
    'hold badge + filter chips render without overflow at 375 width',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final storage = _FakeInquiryStorage();
      final proposalRepo = _FakeProposalRepository([
        _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
        _awaiting('proposal_batch_2', 'student_6', 'template_t1_2'),
      ]);

      await _pumpScreen(tester, proposalRepo: proposalRepo, storage: storage);

      await tester.tap(
        find
            .widgetWithText(OutlinedButton, AppStrings.paymentUnverifiedAction)
            .first,
      );
      await _pumpN(tester, n: 6);
      await tester.tap(find.text(AppStrings.sendMessage));
      await _pumpN(tester);

      expect(find.text(AppStrings.paymentHoldBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
