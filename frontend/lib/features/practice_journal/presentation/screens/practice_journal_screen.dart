import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_screen_scaffold.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/presentation/extensions/journal_tone.dart';
import 'package:lessonaza/features/practice_journal/presentation/widgets/journal_month_grid.dart';

import '../providers/practice_journal_provider.dart';
import 'bound_shelf_screen.dart';

/// 3 역할(학생·보호자·선생님) x 2 톤 연습장 화면.
///
/// - 하단 액션은 역할에 따라 다름.
/// - 쓰기 후 [practiceLedgerProvider] invalidate → 그리드 자동 갱신.
enum JournalRole { student, guardian, teacher }

class PracticeJournalScreen extends ConsumerWidget {
  final String childProfileId;
  final JournalRole role;
  final JournalTone tone;

  const PracticeJournalScreen({
    super.key,
    required this.childProfileId,
    required this.role,
    this.tone = JournalTone.standard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final ledgerAsync = ref.watch(
      practiceLedgerProvider(
        childProfileId: childProfileId,
        year: year,
        month: month,
      ),
    );

    Widget body = ledgerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Text(
              e.toString(),
              style: const TextStyle(color: AppColors.paperMargin),
            ),
          ),
      data: (ledger) => _JournalBody(ledger: ledger),
    );

    return NotebookScreenScaffold(
      appBarTitle: tone.title,
      actions: [
        IconButton(
          tooltip: AppStrings.boundShelfTitle,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => BoundShelfScreen(childProfileId: childProfileId),
                ),
              ),
        ),
      ],
      body: body,
      bottomNavigationBar: _BottomAction(
        childProfileId: childProfileId,
        role: role,
        year: year,
        month: month,
        onSuccess: () {
          ref.invalidate(
            practiceLedgerProvider(
              childProfileId: childProfileId,
              year: year,
              month: month,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _JournalBody extends StatelessWidget {
  final PracticeLedger ledger;

  const _JournalBody({required this.ledger});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.practiceJournalSubtitle,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
          const SizedBox(height: AppSpacing.space2),
          JournalMonthGrid(ledger: ledger),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BottomAction extends ConsumerWidget {
  final String childProfileId;
  final JournalRole role;
  final int year;
  final int month;
  final VoidCallback onSuccess;

  const _BottomAction({
    required this.childProfileId,
    required this.role,
    required this.year,
    required this.month,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String label = switch (role) {
      JournalRole.guardian => AppStrings.journalGuardianSeal,
      JournalRole.teacher => AppStrings.journalTeacherEndorse,
      JournalRole.student => AppStrings.journalSelfEndorse,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space4,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              minimumSize: const Size(0, AppSpacing.buttonHeight),
            ),
            onPressed: () => _onTap(context, ref),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(practiceJournalRepositoryProvider);
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    switch (role) {
      case JournalRole.guardian:
        // Monday of the current week (UTC)
        final weekday = today.weekday; // Mon=1 … Sun=7
        final monday = today.subtract(Duration(days: weekday - 1));
        await repo.addGuardianSeal(
          childProfileId,
          GuardianSeal(weekStart: monday, guardianUserId: 'me'),
        );
      case JournalRole.teacher:
        await repo.addEndorsement(
          childProfileId,
          Endorsement(
            by: EndorsedBy.teacher,
            date: today,
            authorUserId: 'me',
            assignmentRef: 'a1', // P1 placeholder — real picker in later phase
            note: '',
          ),
        );
      case JournalRole.student:
        await repo.addEndorsement(
          childProfileId,
          Endorsement(
            by: EndorsedBy.self,
            date: today,
            authorUserId: 'me',
            note: '',
          ),
        );
    }
    onSuccess();
  }
}
