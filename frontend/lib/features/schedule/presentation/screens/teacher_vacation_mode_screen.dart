import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text(AppStrings.vacationModeTitle)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.space4),
        children: [
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
              onPressed: state.hasValidRange && !state.isLoadingImpact
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

class _ImpactSummary extends StatelessWidget {
  final VacationImpactPreview impact;
  const _ImpactSummary({required this.impact});

  @override
  Widget build(BuildContext context) {
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
        SizedBox(height: AppSpacing.space2),
        for (final student in impact.impactedStudents.take(10))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    student.studentName ?? student.studentId,
                    style: AppTypography.bodyMedium,
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
      ],
    );
  }
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
      child: state.isSubmitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(AppStrings.vacationRegisterButton),
    );
  }
}
