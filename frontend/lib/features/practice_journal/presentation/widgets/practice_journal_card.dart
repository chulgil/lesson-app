import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';

import '../providers/practice_journal_provider.dart';

/// 홈/목록 화면에 삽입하는 이달 연습장 미리보기 카드.
///
/// 이달 연습 도장 수를 표시하고, 탭 시 [onTap] 호출.
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

    final markCount = ledgerAsync.valueOrNull?.markCount ?? 0;
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
              // Title + subtitle
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
                    isLoading
                        ? const SizedBox(
                          height: 12,
                          width: 40,
                          child: LinearProgressIndicator(),
                        )
                        : Text(
                          '$markCount${AppStrings.journalMarkStandard}',
                          style: TextStyle(
                            color: AppColors.inkTertiary,
                            fontSize: 12,
                          ),
                        ),
                  ],
                ),
              ),
              // Trailing chevron
              const Icon(Icons.chevron_right, color: AppColors.inkQuaternary),
            ],
          ),
        ),
      ),
    );
  }
}
