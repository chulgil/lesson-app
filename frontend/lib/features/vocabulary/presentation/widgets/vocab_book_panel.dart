import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../providers/vocab_sets_provider.dart';
import '../screens/vocab_review_page.dart';
import '../screens/vocab_sets_page.dart';

/// The 단어장 tab body inside the language practice-tools modal (#1124).
///
/// A launcher, not a workspace: a one-line due summary plus two full-screen
/// entries (start review / manage sets). Tapping either closes the modal and
/// pushes the destination, so CRUD and review live on their own screens.
/// Resilient to a not-yet-initialized store — a load error falls back to the
/// "nothing due" copy rather than crashing the modal.
class VocabBookPanel extends ConsumerWidget {
  const VocabBookPanel({super.key, this.studentId});

  /// Practice student context threaded through the modal; unused for now (the
  /// first slice is student self-study), kept for parity with other tool panels.
  final String? studentId;

  void _open(BuildContext context, Widget page) {
    final navigator = Navigator.of(context);
    navigator.pop(); // close the practice-tools modal
    navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(vocabSummaryProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        children: [
          const Spacer(),
          const Icon(
            Icons.style_outlined,
            size: 32,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space4),
          summary.when(
            loading: () => _summary(AppStrings.vocabNoDue, null),
            error: (_, __) => _summary(AppStrings.vocabNoDue, null),
            data:
                (s) => _summary(
                  s.dueCount > 0
                      ? AppStrings.vocabDueWaiting(s.dueCount)
                      : AppStrings.vocabNoDue,
                  AppStrings.vocabSetCount(s.setCount),
                ),
          ),
          const Spacer(),
          _navButton(
            context,
            AppStrings.vocabReviewCta,
            const VocabReviewPage(),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.space2),
          _navButton(
            context,
            AppStrings.vocabManageCta,
            const VocabSetsPage(),
            emphasized: false,
          ),
        ],
      ),
    );
  }

  Widget _summary(String title, String? subtitle) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: NotebookTypography.pieceTitle.copyWith(
          color: AppColors.inkSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.space1),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
      ],
    ],
  );

  Widget _navButton(
    BuildContext context,
    String label,
    Widget page, {
    required bool emphasized,
  }) {
    final color = emphasized ? AppColors.ink : AppColors.inkSecondary;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _open(context, page),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
        child: Text(
          label,
          style: NotebookTypography.sectionLabel.copyWith(color: color),
        ),
      ),
    );
  }
}
