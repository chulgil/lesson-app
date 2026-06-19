import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/features/subscription/data/repositories/payment_inquiry_storage.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_proposal_repository.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/providers/payment_inquiry_provider.dart';
import 'package:lessonaza/features/subscription/presentation/screens/proposal_confirm_screen.dart';

/// In-memory inquiry storage — avoids Hive.
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

/// Spy on the one method #80 exercises; everything else is unimplemented.
class _SpySubscriptionRepository implements SubscriptionRepository {
  _SpySubscriptionRepository({this.notified = true, this.error});

  final bool notified;
  final Object? error;
  final List<String> calls = [];

  @override
  Future<bool> requestPaymentConfirmation(String proposalId) async {
    calls.add(proposalId);
    if (error != null) throw error!;
    return notified;
  }

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
  required _SpySubscriptionRepository subscriptionRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProposalRepositoryProvider.overrideWithValue(proposalRepo),
        paymentInquiryStorageProvider.overrideWithValue(storage),
        subscriptionRepositoryProvider.overrideWithValue(subscriptionRepo),
      ],
      child: const MaterialApp(
        home: ProposalConfirmScreen(teacherId: 'teacher_1'),
      ),
    ),
  );
  await _pumpN(tester);
}

Future<void> _tapInquiryAndConfirm(WidgetTester tester) async {
  await tester.tap(
    find
        .widgetWithText(OutlinedButton, AppStrings.paymentUnverifiedAction)
        .first,
  );
  await _pumpN(tester, n: 6);
  await tester.tap(find.text(AppStrings.sendMessage));
  await _pumpN(tester);
}

void main() {
  testWidgets(
    'confirming 입금 미확인 calls requestPaymentConfirmation and shows sent message',
    (tester) async {
      final spy = _SpySubscriptionRepository(notified: true);
      await _pumpScreen(
        tester,
        proposalRepo: _FakeProposalRepository([
          _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
        ]),
        storage: _FakeInquiryStorage(),
        subscriptionRepo: spy,
      );

      await _tapInquiryAndConfirm(tester);

      expect(spy.calls, ['proposal_batch_1']);
      expect(find.text(AppStrings.inquiryMessageSent), findsOneWidget);
    },
  );

  testWidgets('cooldown (409) shows the cooldown message', (tester) async {
    final spy = _SpySubscriptionRepository(
      error: const ApiException(message: 'cooldown', statusCode: 409),
    );
    await _pumpScreen(
      tester,
      proposalRepo: _FakeProposalRepository([
        _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
      ]),
      storage: _FakeInquiryStorage(),
      subscriptionRepo: spy,
    );

    await _tapInquiryAndConfirm(tester);

    expect(spy.calls, ['proposal_batch_1']);
    expect(find.text(AppStrings.paymentInquiryCooldown), findsOneWidget);
  });

  testWidgets('offline student (notified=false) shows the no-account message', (
    tester,
  ) async {
    final spy = _SpySubscriptionRepository(notified: false);
    await _pumpScreen(
      tester,
      proposalRepo: _FakeProposalRepository([
        _awaiting('proposal_batch_1', 'student_4', 'template_t1_1'),
      ]),
      storage: _FakeInquiryStorage(),
      subscriptionRepo: spy,
    );

    await _tapInquiryAndConfirm(tester);

    expect(find.text(AppStrings.paymentInquiryNoAccount), findsOneWidget);
  });
}
