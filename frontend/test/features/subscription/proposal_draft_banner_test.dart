import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/proposal_draft_storage.dart';
import 'package:lessonaza/features/subscription/presentation/providers/proposal_draft_provider.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/proposal_draft_banner.dart';

/// Hive-free fake — overrides every storage method the banner touches.
class _FakeDraftStorage extends ProposalDraftStorage {
  final List<String> deletedKeys = [];

  @override
  Future<void> delete(String userId, String studentId) async {
    deletedKeys.add('$userId:$studentId');
  }

  @override
  Future<ProposalDraftLoadResult> load(String userId, String studentId) async {
    return const ProposalDraftLoadResult(draft: null);
  }
}

ProposalDraft _draft({int ageDays = 1}) => ProposalDraft(
  templateId: 'tpl-1',
  amount: 320000,
  totalLessons: 8,
  validityDays: 90,
  membershipId: 'm-1',
  savedAt: DateTime.now().subtract(Duration(days: ageDays)),
  ageDays: ageDays,
);

Widget _wrap({
  required ProposalDraft? draft,
  required ProposalDraftStorage storage,
  void Function(ProposalDraft)? onResume,
  VoidCallback? onDiscard,
}) {
  return ProviderScope(
    overrides: [
      proposalDraftStorageProvider.overrideWithValue(storage),
      proposalDraftProvider('u1', 's1').overrideWith((ref) async => draft),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ProposalDraftBanner(
          userId: 'u1',
          studentId: 's1',
          onResume: onResume ?? (_) {},
          onDiscard: onDiscard ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows title and resume CTA when a valid draft exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(draft: _draft(), storage: _FakeDraftStorage()),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.proposalDraftBannerTitle), findsOneWidget);
    expect(find.text(AppStrings.proposalDraftBannerResume), findsOneWidget);
  });

  testWidgets('renders nothing when no draft exists', (tester) async {
    await tester.pumpWidget(_wrap(draft: null, storage: _FakeDraftStorage()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.proposalDraftBannerTitle), findsNothing);
  });

  testWidgets('tapping resume invokes onResume with the draft', (tester) async {
    ProposalDraft? resumed;
    await tester.pumpWidget(
      _wrap(
        draft: _draft(ageDays: 3),
        storage: _FakeDraftStorage(),
        onResume: (d) => resumed = d,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.proposalDraftBannerResume));
    await tester.pumpAndSettle();

    expect(resumed, isNotNull);
    expect(resumed!.amount, 320000);
    expect(resumed!.ageDays, 3);
  });

  testWidgets('close → confirm discards the draft via storage', (tester) async {
    final storage = _FakeDraftStorage();
    var discarded = false;
    await tester.pumpWidget(
      _wrap(
        draft: _draft(),
        storage: storage,
        onDiscard: () => discarded = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.proposalDraftDiscardTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.proposalDraftDiscardConfirm));
    await tester.pumpAndSettle();

    expect(storage.deletedKeys, contains('u1:s1'));
    expect(discarded, isTrue);
  });
}
