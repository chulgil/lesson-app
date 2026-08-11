import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_bottom_sheet.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_screen_scaffold.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/guardian_seal.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
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
          const SizedBox(height: AppSpacing.space4),
          const _ActorLegend(),
          _SelfNotesSection(endorsements: ledger.endorsements),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// 도장 actor 범례 — 3가지 의미를 한눈에 설명.
class _ActorLegend extends StatelessWidget {
  const _ActorLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.journalActorLegendTitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        _LegendRow(
          glyph: NotebookGlyph.dotFilled,
          color: AppColors.ink,
          label: AppStrings.journalActorStudentDesc,
        ),
        _LegendRow(
          glyph: NotebookGlyph.heartOutline,
          color: AppColors.inkSecondary,
          label: AppStrings.journalActorGuardianDesc,
        ),
        _LegendRow(
          glyph: NotebookGlyph.check,
          color: AppColors.inkSecondary,
          label: AppStrings.journalActorTeacherDesc,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String glyph;
  final Color color;
  final String label;

  const _LegendRow({
    required this.glyph,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NotebookGlyph(glyph, size: 12, color: color),
          const SizedBox(width: AppSpacing.space2),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
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
    final userId = ref.read(currentUserIdProvider);
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Guard the write: mock validation (teacher endorsement requires an
    // assignmentRef the Phase-2 picker doesn't yet supply -> ArgumentError) used
    // to throw out of this button callback and be swallowed with no UI feedback.
    // Surface failures and only refresh the grid on real success.
    try {
      switch (role) {
        case JournalRole.guardian:
          // Monday of the current week (UTC)
          final weekday = today.weekday; // Mon=1 … Sun=7
          final monday = today.subtract(Duration(days: weekday - 1));
          await repo.addGuardianSeal(
            childProfileId,
            GuardianSeal(weekStart: monday, guardianUserId: userId),
          );
        case JournalRole.teacher:
          await repo.addEndorsement(
            childProfileId,
            Endorsement(
              by: EndorsedBy.teacher,
              date: today,
              authorUserId: userId,
              // assignmentRef: real picker not yet implemented — null until Phase 2
              note: '',
            ),
          );
        case JournalRole.student:
          // Optional one-line note, zero added friction: empty field still
          // signs with note:'' (unchanged behavior); sheet dismissed (null)
          // cancels the whole write.
          final note = await showNotebookModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const _SelfEndorseSheet(),
          );
          if (note == null) return;
          await repo.addEndorsement(
            childProfileId,
            Endorsement(
              by: EndorsedBy.self,
              date: today,
              authorUserId: userId,
              note: note,
            ),
          );
      }
      onSuccess();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.errorTryAgain)));
    }
  }
}

// ---------------------------------------------------------------------------

/// 자가 검인 시 선택적으로 남기는 한 줄 메모 입력 시트.
///
/// 필드를 비운 채 서명하면 기존과 동일하게 note:'' 로 저장된다(마찰 0).
/// 시트를 닫으면(barrier tap 등) null 을 반환해 서명 자체를 취소한다.
class _SelfEndorseSheet extends StatefulWidget {
  const _SelfEndorseSheet();

  @override
  State<_SelfEndorseSheet> createState() => _SelfEndorseSheetState();
}

class _SelfEndorseSheetState extends State<_SelfEndorseSheet> {
  static const noteFieldKey = Key('self_endorse_note_field');
  static const signButtonKey = Key('self_endorse_sheet_sign_button');

  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _sign() {
    Navigator.of(context).pop(_noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: noteFieldKey,
              controller: _noteController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: AppStrings.journalSelfEndorseNoteHint,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: signButtonKey,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperAccent,
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                ),
                onPressed: _sign,
                child: const Text(AppStrings.journalSelfEndorse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// 자가 검인 메모 읽기 전용 목록 — [Endorsement.note] 가 이전엔 어디서도
/// 표시되지 않았음(입력 UI 부재로 항상 빈 문자열) 을 보완.
///
/// 메모가 있는 self 검인만, 최신순으로 보여준다. 메모가 하나도 없으면 아무것도
/// 렌더링하지 않는다(빈 상태 배너 불필요 — 목록 자체가 선택적 기능).
class _SelfNotesSection extends StatelessWidget {
  final List<Endorsement> endorsements;

  const _SelfNotesSection({required this.endorsements});

  @override
  Widget build(BuildContext context) {
    final notes =
        endorsements
            .where((e) => e.by == EndorsedBy.self && e.note.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (notes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.space4),
        Text(
          AppStrings.journalSelfNotesTitle,
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        for (final endorsement in notes) _SelfNoteRow(endorsement: endorsement),
      ],
    );
  }
}

class _SelfNoteRow extends StatelessWidget {
  final Endorsement endorsement;

  const _SelfNoteRow({required this.endorsement});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotebookGlyph(
            NotebookGlyph.dotFilled,
            size: 12,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              endorsement.note,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
