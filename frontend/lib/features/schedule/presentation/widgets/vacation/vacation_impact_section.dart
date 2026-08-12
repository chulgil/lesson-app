import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../domain/entities/vacation_period.dart';
import '../../providers/vacation_providers.dart';

/// Schema-enum -> user-facing label. Shared by the impact detail list, the
/// added-segments list, and the submit summary dialog (#768 ②).
String vacationDispositionLabel(VacationDisposition d) {
  switch (d) {
    case VacationDisposition.makeupCredit:
      return AppStrings.vacationDispositionMakeupCreditLabel;
    case VacationDisposition.freeCancel:
      return AppStrings.vacationDispositionFreeCancelLabel;
    case VacationDisposition.rollForward:
      return AppStrings.vacationDispositionRollForwardLabel;
  }
}

/// Impact preview for the draft vacation range (UI complexity audit rank 5).
///
/// Progressive disclosure: collapsed to a hint before a valid range is
/// picked, auto-computes in the background once one is (no manual refresh),
/// and shows a compact "레슨 N건 · 학생 M명" badge — tapping it expands the
/// per-student detail list.
class VacationImpactSection extends ConsumerStatefulWidget {
  const VacationImpactSection({super.key});

  @override
  ConsumerState<VacationImpactSection> createState() =>
      _VacationImpactSectionState();
}

class _VacationImpactSectionState extends ConsumerState<VacationImpactSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Auto-compute in the background whenever a valid draft range has no
    // impact loaded yet — mirrors the repository call the manual refresh
    // button used to make. Re-fires on every date change (setDraftStart/End
    // already clear impact) and skips while a request is already in flight.
    ref.listen<VacationFormState>(vacationFormProvider, (previous, next) {
      if (next.hasValidDraft && next.impact == null && !next.isLoadingImpact) {
        ref.read(vacationFormProvider.notifier).loadImpact();
      }
    });

    final state = ref.watch(vacationFormProvider);
    final impact = state.impact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ImpactHeader(),
        SizedBox(height: AppSpacing.space2),
        if (!state.hasValidDraft)
          _ImpactHint(text: AppStrings.vacationRangeNeeded)
        else if (impact == null)
          const _ImpactLoadingRow()
        else if (impact.impactedLessonCount == 0)
          _ImpactHint(text: AppStrings.vacationImpactEmpty)
        else ...[
          _ImpactBadge(
            impact: impact,
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            SizedBox(height: AppSpacing.space2),
            _ImpactDetailList(impact: impact),
          ],
        ],
      ],
    );
  }
}

class _ImpactHeader extends StatelessWidget {
  const _ImpactHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.vacationImpactSection,
      style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
    );
  }
}

class _ImpactHint extends StatelessWidget {
  final String text;
  const _ImpactHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.inkTertiary),
    );
  }
}

class _ImpactLoadingRow extends StatelessWidget {
  const _ImpactLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.space2),
        Text(
          AppStrings.vacationImpactLoading,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
      ],
    );
  }
}

/// Compact "레슨 N건 · 학생 M명" summary — tap to expand the detail list.
class _ImpactBadge extends StatelessWidget {
  final VacationImpactPreview impact;
  final bool expanded;
  final VoidCallback onTap;

  const _ImpactBadge({
    required this.impact,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.vacationImpactSummary(
                lessonCount: impact.impactedLessonCount,
                studentCount: impact.impactedStudentCount,
              ),
              style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
            ),
          ),
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: AppColors.inkTertiary,
          ),
        ],
      ),
    );
  }
}

class _ImpactDetailList extends ConsumerWidget {
  final VacationImpactPreview impact;
  const _ImpactDetailList({required this.impact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(
      vacationFormProvider.select((s) => s.perStudentOverrides),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.vacationPerStudentSheetHint,
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        SizedBox(height: AppSpacing.space2),
        for (final student in impact.impactedStudents.take(10))
          _ImpactStudentRow(
            student: student,
            dispositionOverride: overrides[student.studentId],
            onLongPress:
                () => _openPerStudentSheet(
                  context,
                  ref,
                  studentId: student.studentId,
                  studentLabel: student.studentName ?? student.studentId,
                ),
          ),
      ],
    );
  }
}

class _ImpactStudentRow extends StatelessWidget {
  final VacationImpactedStudent student;
  final VacationDisposition? dispositionOverride;
  final VoidCallback onLongPress;
  const _ImpactStudentRow({
    required this.student,
    required this.dispositionOverride,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      onTap: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName ?? student.studentId,
                    style: AppTypography.bodyMedium,
                  ),
                  if (dispositionOverride != null) ...[
                    SizedBox(height: 2),
                    Text(
                      AppStrings.vacationPerStudentOverrideLabel(
                        vacationDispositionLabel(dispositionOverride!),
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              AppStrings.vacationImpactStudentCount(student.lessonCount),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openPerStudentSheet(
  BuildContext context,
  WidgetRef ref, {
  required String studentId,
  required String studentLabel,
}) async {
  final current = ref.read(vacationFormProvider).perStudentOverrides[studentId];
  final selected = await showNotebookBottomSheet<VacationDisposition?>(
    context: context,
    builder: (sheetCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.vacationPerStudentSheetTitle,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          SizedBox(height: AppSpacing.space1),
          Text(
            studentLabel,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.space3),
          for (final option in VacationDisposition.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vacationDispositionLabel(option)),
              trailing:
                  current == option
                      ? const Icon(Icons.check, color: AppColors.paperAccent)
                      : null,
              onTap: () => Navigator.pop(sheetCtx, option),
            ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.vacationPerStudentUseDefault),
            trailing:
                current == null
                    ? const Icon(Icons.check, color: AppColors.paperAccent)
                    : null,
            onTap: () => Navigator.pop(sheetCtx, null),
          ),
        ],
      );
    },
  );

  // If the user dismissed by tapping the scrim, selected is null *and* we
  // were already at "no override". Treat dismiss as no-op via mounted check.
  if (!context.mounted) return;
  // showModalBottomSheet returns the popped value; null means user picked
  // "기본값 사용". To distinguish dismiss vs explicit "기본값 사용", we always
  // apply the popped value (Map<...> = null is safe).
  ref
      .read(vacationFormProvider.notifier)
      .setStudentOverride(studentId, selected);
}
