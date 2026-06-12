import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_proposal_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_proposal.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_proposal_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/duplicate_proposal_dialog.dart';

SubscriptionProposal _pendingProposal() => SubscriptionProposal(
  id: 'p-1',
  teacherId: 't-1',
  studentId: 's-1',
  templateId: 'tpl-1',
  status: ProposalStatus.pending,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(days: 7)),
);

/// Delay-free seeded fake — the base mock's `Future.delayed` timers never
/// fire inside the testWidgets FakeAsync zone and deadlock the test.
class _SeededProposalRepository extends MockSubscriptionProposalRepository {
  _SeededProposalRepository({this.active});

  final SubscriptionProposal? active;

  @override
  Future<SubscriptionProposal?> getActiveProposal(
    String teacherId,
    String studentId,
  ) async => active;
}

/// Pumps a host screen with a button that runs [ensureNoDuplicateProposal]
/// and records its result.
Widget _host(
  MockSubscriptionProposalRepository repo,
  void Function(bool) onResult,
) {
  return ProviderScope(
    overrides: [subscriptionProposalRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Consumer(
        builder:
            (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final proceed = await ensureNoDuplicateProposal(
                      context: context,
                      ref: ref,
                      teacherId: 't-1',
                      studentId: 's-1',
                      studentName: '김연습',
                    );
                    onResult(proceed);
                  },
                  child: const Text('go'),
                ),
              ),
            ),
      ),
    ),
  );
}

void main() {
  testWidgets('no active proposal → proceeds without dialog', (tester) async {
    final repo = _SeededProposalRepository();
    bool? result;

    await tester.pumpWidget(_host(repo, (r) => result = r));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text(AppStrings.duplicateProposalDialogTitle), findsNothing);
  });

  testWidgets('active proposal → dialog shown; dismiss blocks creation', (
    tester,
  ) async {
    final repo = _SeededProposalRepository(active: _pendingProposal());
    bool? result;

    await tester.pumpWidget(_host(repo, (r) => result = r));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.duplicateProposalDialogTitle), findsOneWidget);
    expect(
      find.text(AppStrings.duplicateProposalDialogBody('김연습')),
      findsOneWidget,
    );

    // Dismiss via the barrier — creation must not proceed.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
