import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/endorsement.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';

import '../providers/practice_journal_provider.dart';

/// 홈/목록 화면에 삽입하는 이달 연습장 미리보기 카드.
///
/// 이달 연습 도장 수를 actor별(학생·보호자·선생님)로 표시하고, 탭 시 [onTap] 호출.
/// Smoke test HARD-GATE: pump + tap → onTap fired, no exception.
class PracticeJournalCard extends ConsumerWidget {
  final String childProfileId;
  final JournalRole role;
  final VoidCallback onTap;

  const PracticeJournalCard({
    super.key,
    required this.childProfileId,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final ledgerAsync = ref.watch(
      practiceLedgerProvider(
        childProfileId: childProfileId,
        year: now.year,
        month: now.month,
      ),
    );

    final isLoading = ledgerAsync.isLoading;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Leading glyph — signature area
              NotebookGlyph(
                NotebookGlyph.dotFilled,
                size: AppSpacing.iconMD,
                color: AppColors.paperAccent,
                semanticLabel: AppStrings.journalMarkStandard,
              ),
              const SizedBox(width: AppSpacing.space3),
              // Title + actor-breakdown subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.journalTitleStandard,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isLoading)
                      const SizedBox(
                        height: 12,
                        width: 40,
                        child: LinearProgressIndicator(),
                      )
                    else
                      _ActorSummaryRow(ledger: ledgerAsync.valueOrNull),
                  ],
                ),
              ),
              // Trailing chevron (system affordance — Material allowed here)
              const Icon(Icons.chevron_right, color: AppColors.inkQuaternary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Actor별 도장 수를 한 행으로 표시.
/// 학생(●) · 보호자(♡) · 선생님(✓) 각각 카운트.
class _ActorSummaryRow extends StatelessWidget {
  final PracticeLedger? ledger;

  const _ActorSummaryRow({this.ledger});

  @override
  Widget build(BuildContext context) {
    final l = ledger;
    final studentCount = l?.marks.length ?? 0;
    final guardianCount = l?.seals.length ?? 0;
    final teacherCount =
        l?.endorsements.where((e) => e.by == EndorsedBy.teacher).length ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActorChip(
          glyph: NotebookGlyph.dotFilled,
          count: studentCount,
          label: AppStrings.journalLegendStudent,
          color: AppColors.ink,
        ),
        const SizedBox(width: AppSpacing.space2),
        _ActorChip(
          glyph: NotebookGlyph.heartOutline,
          count: guardianCount,
          label: AppStrings.journalLegendGuardian,
          color: AppColors.inkSecondary,
        ),
        const SizedBox(width: AppSpacing.space2),
        _ActorChip(
          glyph: NotebookGlyph.check,
          count: teacherCount,
          label: AppStrings.journalLegendTeacher,
          color: AppColors.inkSecondary,
        ),
      ],
    );
  }
}

/// 글리프 + 숫자 한 쌍 (시그니처 영역 — NotebookGlyph 사용).
class _ActorChip extends StatelessWidget {
  final String glyph;
  final int count;
  final String label;
  final Color color;

  const _ActorChip({
    required this.glyph,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotebookGlyph(glyph, size: 11, color: color),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: TextStyle(color: AppColors.inkTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
