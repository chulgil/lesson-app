import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../domain/entities/vacation_period.dart';
import '../providers/vacation_providers.dart';

/// Teacher vacation mode entry screen (#431, G3).
///
/// 본 화면은 **골격** 이다. 현재 PR 범위:
/// - 기간 선택 (시작/종료) + 사유 입력
/// - 영향 받는 레슨 미리보기 (BE GET impact)
/// - 휴가 등록 (BE POST) — default disposition = rollForward
///
/// 후속 PR:
/// - 3 옵션 (보강 크레딧 / 무료 처리 / 이월) UI 선택
/// - 학생별 처리 옵션 변경 (long-press)
/// - 활성 휴가 카드 + 24h Recovery 버튼
/// - LNZ_TEACHER_VACATION 알림톡 트리거 표시
class TeacherVacationModeScreen extends ConsumerWidget {
  const TeacherVacationModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vacationFormProvider);
    final notifier = ref.read(vacationFormProvider.notifier);

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.vacationModeTitle,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.space4),
        children: [
          // Active vacations + 24h Recovery (spec §7 + §9.1).
          const _ActiveVacationSection(),
          SizedBox(height: AppSpacing.space4),
          _SectionHeader(text: AppStrings.vacationPeriodSection),
          SizedBox(height: AppSpacing.space2),
          _DateRow(
            label: AppStrings.vacationStartDateLabel,
            date: state.startDate,
            onPick: (d) => notifier.setStartDate(d),
          ),
          _DateRow(
            label: AppStrings.vacationEndDateLabel,
            date: state.endDate,
            onPick: (d) => notifier.setEndDate(d),
          ),
          if (state.startDate != null &&
              state.endDate != null &&
              !state.hasValidRange)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.space1),
              child: Text(
                AppStrings.vacationDateRangeInvalid,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ),
          SizedBox(height: AppSpacing.space3),
          _ReasonField(value: state.reason, onChanged: notifier.setReason),
          SizedBox(height: AppSpacing.space4),
          _ImpactSection(state: state, onRefresh: notifier.loadImpact),
          SizedBox(height: AppSpacing.space4),
          _DispositionSection(
            selected: state.disposition,
            onChange: notifier.setDisposition,
          ),
          SizedBox(height: AppSpacing.space5),
          _SubmitButton(state: state, onSubmit: () => _onSubmit(context, ref)),
        ],
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(vacationFormProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await notifier.submit();
    if (result != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.vacationRegisterSuccess)),
      );
      if (navigator.canPop()) navigator.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.vacationRegisterFailed)),
      );
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Private widgets — kept colocated to honor "skeleton" scope.
// ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DateRow({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            Text(label, style: AppTypography.bodyLarge),
            const Spacer(),
            Text(
              date == null ? '—' : _formatDate(date!),
              style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPick(picked);
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _ReasonField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ReasonField({required this.value, required this.onChanged});

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: AppStrings.vacationReasonLabel,
        hintText: AppStrings.vacationReasonHint,
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _ImpactSection extends StatelessWidget {
  final VacationFormState state;
  final Future<void> Function() onRefresh;

  const _ImpactSection({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _SectionHeader(text: AppStrings.vacationImpactSection),
            const Spacer(),
            TextButton(
              onPressed:
                  state.hasValidRange && !state.isLoadingImpact
                      ? onRefresh
                      : null,
              child: const Text(AppStrings.vacationImpactRefresh),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.space2),
        if (state.isLoadingImpact)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.impact == null)
          Text(
            AppStrings.vacationRangeNeeded,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          )
        else if (state.impact!.impactedLessonCount == 0)
          Text(
            AppStrings.vacationImpactEmpty,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          )
        else
          _ImpactSummary(impact: state.impact!),
      ],
    );
  }
}

class _ImpactSummary extends ConsumerWidget {
  final VacationImpactPreview impact;
  const _ImpactSummary({required this.impact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(
      vacationFormProvider.select((s) => s.perStudentOverrides),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.vacationImpactSummary(
            lessonCount: impact.impactedLessonCount,
            studentCount: impact.impactedStudentCount,
          ),
          style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
        ),
        SizedBox(height: AppSpacing.space1),
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

/// Schema-enum → user-facing label. Used by per-student row + sheet.
String _dispositionLabel(VacationDisposition d) {
  switch (d) {
    case VacationDisposition.makeupCredit:
      return AppStrings.vacationDispositionMakeupCreditLabel;
    case VacationDisposition.freeCancel:
      return AppStrings.vacationDispositionFreeCancelLabel;
    case VacationDisposition.rollForward:
      return AppStrings.vacationDispositionRollForwardLabel;
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
                        _dispositionLabel(dispositionOverride!),
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
  final selected = await showModalBottomSheet<VacationDisposition?>(
    context: context,
    backgroundColor: AppColors.paper,
    showDragHandle: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space4,
            0,
            AppSpacing.space4,
            AppSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.vacationPerStudentSheetTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
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
                  title: Text(_dispositionLabel(option)),
                  trailing:
                      current == option
                          ? const Icon(
                            Icons.check,
                            color: AppColors.paperAccent,
                          )
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
          ),
        ),
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

class _SubmitButton extends StatelessWidget {
  final VacationFormState state;
  final VoidCallback onSubmit;
  const _SubmitButton({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        state.hasValidRange && !state.isSubmitting && !state.isLoadingImpact;
    return FilledButton(
      onPressed: canSubmit ? onSubmit : null,
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      child:
          state.isSubmitting
              ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Text(AppStrings.vacationRegisterButton),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Disposition section — 3 options (H-001 spec §4.1 step 3 / §5).
// ──────────────────────────────────────────────────────────────

class _DispositionSection extends StatelessWidget {
  final VacationDisposition selected;
  final ValueChanged<VacationDisposition> onChange;
  const _DispositionSection({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(text: AppStrings.vacationDispositionSection),
        SizedBox(height: AppSpacing.space2),
        _DispositionOption(
          value: VacationDisposition.makeupCredit,
          label: AppStrings.vacationDispositionMakeupCreditLabel,
          description: AppStrings.vacationDispositionMakeupCreditDescription,
          isRecommended: true,
          groupValue: selected,
          onChange: onChange,
        ),
        _DispositionOption(
          value: VacationDisposition.freeCancel,
          label: AppStrings.vacationDispositionFreeCancelLabel,
          description: AppStrings.vacationDispositionFreeCancelDescription,
          groupValue: selected,
          onChange: onChange,
        ),
        _DispositionOption(
          value: VacationDisposition.rollForward,
          label: AppStrings.vacationDispositionRollForwardLabel,
          description: AppStrings.vacationDispositionRollForwardDescription,
          groupValue: selected,
          onChange: onChange,
        ),
      ],
    );
  }
}

class _DispositionOption extends StatelessWidget {
  final VacationDisposition value;
  final VacationDisposition groupValue;
  final String label;
  final String description;
  final bool isRecommended;
  final ValueChanged<VacationDisposition> onChange;

  const _DispositionOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.description,
    required this.onChange,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap: () => onChange(value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color:
                  isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio-like indicator. Custom (not Material Radio) to avoid the
              // deprecated groupValue/onChanged API in Flutter 3.32+.
              Container(
                width: 20,
                height: 20,
                margin: EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkTertiary,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.paperAccent,
                            ),
                          ),
                        )
                        : null,
              ),
              SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRecommended) ...[
                          SizedBox(width: AppSpacing.space2),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.space2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paperAccent,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSmall,
                              ),
                            ),
                            child: Text(
                              AppStrings.vacationDispositionRecommended,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.paper,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: AppSpacing.space1),
                    Text(
                      description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Active vacation card + Recovery (H-001 FE Phase 3).
// Spec: docs/specs/schedule/teacher_vacation_mode.md §7.
// ──────────────────────────────────────────────────────────────

class _ActiveVacationSection extends ConsumerWidget {
  const _ActiveVacationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(vacationListProvider);
    return listAsync.when(
      data: (vacations) {
        if (vacations.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(text: AppStrings.vacationActiveSection),
            SizedBox(height: AppSpacing.space2),
            ...vacations.map((v) => _ActiveVacationCard(period: v)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ActiveVacationCard extends ConsumerWidget {
  final VacationPeriod period;
  const _ActiveVacationCard({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.space2),
      padding: EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.vacationCardDateRange(
                    _formatShortDate(period.startDate),
                    _formatShortDate(period.endDate),
                  ),
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                ),
                if (period.reason != null && period.reason!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.space1),
                  Text(
                    period.reason!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _confirmCancel(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              foregroundColor: AppColors.paperAccent,
              side: const BorderSide(color: AppColors.paperAccent),
            ),
            child: const Text(AppStrings.vacationCancelLabel),
          ),
        ],
      ),
    );
  }

  static String _formatShortDate(DateTime d) {
    return '${d.month}/${d.day}';
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            title: AppStrings.vacationCancelConfirmTitle,
            content: const Text(AppStrings.vacationCancelConfirmBody),
            confirmLabel: AppStrings.vacationCancelLabel,
            cancelLabel: AppStrings.cancel,
            isDestructive: true,
            onConfirm: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
    );
    if (result != true || !context.mounted) return;
    try {
      await ref.read(vacationActionsProvider).cancel(period.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.vacationCancelSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString();
      // Map server error semantics to friendly text (spec §7.2).
      final friendly =
          message.contains('이미 시작')
              ? AppStrings.vacationCancelAlreadyStarted
              : message.contains('24')
              ? AppStrings.vacationCancelWindowExpired
              : message.contains('이미 취소')
              ? AppStrings.vacationCancelAlreadyCancelled
              : AppStrings.vacationCancelFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    }
  }
}
