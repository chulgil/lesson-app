import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_banner.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../domain/entities/vacation_period.dart';
import '../providers/vacation_providers.dart';
import '../widgets/vacation/vacation_impact_section.dart';

/// Teacher vacation mode entry screen (#431, G3).
///
/// 구현 현황 (Phase 2-3 완료):
/// A1. 3 옵션 선택 (보강 크레딧 / 무료 처리 / 이월) — ✓ 구현됨
/// A2. 학생별 처리 옵션 변경 (long-press 오버라이드) — ✓ 구현됨
/// A3. 활성 휴가 카드 + 24h Recovery (취소) — ✓ 구현됨
/// A5. 다구간 휴가 (구간 추가/제거) — ✓ 구현됨
///
/// 미구현 항목 (BE 대기):
/// A4. LNZ_TEACHER_VACATION 알림톡 발송 + 인앱 수신 UI — 백엔드 알림 큐 준비 후
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
          // 휴가 처리 안내 (검토 #14) — 이 기간 레슨 = 휴강 처리 + 보상.
          const NotebookBanner(
            message: AppStrings.vacationModeGuide,
            leadingIcon: Icons.info_outline,
          ),
          // Active vacations + 24h Recovery (spec §7 + §9.1).
          const _ActiveVacationSection(),
          // 추가한 휴가 구간 (다구간, #768 ②).
          if (state.segments.isNotEmpty) ...[
            SizedBox(height: AppSpacing.space4),
            _AddedSegmentsSection(
              segments: state.segments,
              onRemove: notifier.removeSegment,
            ),
          ],
          SizedBox(height: AppSpacing.space4),
          _SectionHeader(text: AppStrings.vacationPeriodSection),
          SizedBox(height: AppSpacing.space2),
          _DateRow(
            label: AppStrings.vacationStartDateLabel,
            date: state.draftStart,
            onPick: (d) => notifier.setDraftStart(d),
            disablePast: true,
          ),
          _DateRow(
            label: AppStrings.vacationEndDateLabel,
            date: state.draftEnd,
            onPick: (d) => notifier.setDraftEnd(d),
          ),
          if (state.draftStart != null &&
              state.draftEnd != null &&
              !state.hasValidDraft)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.space1),
              child: Text(
                AppStrings.vacationDateRangeInvalid,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ),
          SizedBox(height: AppSpacing.space4),
          // 영향 미리보기 — 유효한 기간이 잡히면 자동으로 계산된다 (수동 새로고침 없음).
          const VacationImpactSection(),
          SizedBox(height: AppSpacing.space4),
          // 처리 방식은 영향 미리보기가 준비된 뒤에야 의미가 있다 (점진적 공개).
          if (state.impact != null) ...[
            _DispositionSection(
              selected: state.draftDisposition,
              onChange: notifier.setDraftDisposition,
              projectedExtensionDays: _projectedExtensionDays(state),
            ),
            SizedBox(height: AppSpacing.space1),
          ],
          // 여러 기간을 묶으려면 '구간 추가' (다구간, #768 ②).
          _AddSegmentButton(
            state: state,
            onAdd: () => _onAddSegment(context, ref),
          ),
          SizedBox(height: AppSpacing.space3),
          _ReasonField(value: state.reason, onChanged: notifier.setReason),
          SizedBox(height: AppSpacing.space5),
          _SubmitButton(state: state, onSubmit: () => _onSubmit(context, ref)),
        ],
      ),
    );
  }

  /// Inclusive day count of the picked range, or null when range is invalid.
  /// Mirrors VacationPeriod.vacationDays; BE confirms the actual extension.
  int? _projectedExtensionDays(VacationFormState state) {
    if (!state.hasValidDraft) return null;
    final diff = state.draftEnd!.difference(state.draftStart!).inDays;
    return diff < 0 ? null : diff + 1;
  }

  /// Commit the current draft as a segment, surfacing overlap/invalid reasons.
  void _onAddSegment(BuildContext context, WidgetRef ref) {
    final overlap = ref.read(vacationFormProvider).draftOverlaps;
    final ok = ref.read(vacationFormProvider.notifier).addSegment();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            overlap
                ? AppStrings.vacationSegmentOverlapError
                : AppStrings.vacationSegmentInvalidError,
          ),
        ),
      );
    }
  }

  Future<void> _onSubmit(BuildContext context, WidgetRef ref) async {
    final formState = ref.read(vacationFormProvider);
    final segments = formState.effectiveSegments;
    if (segments.isEmpty) return;
    // 최종 확인 요약 (구간별 기간 + 보상). #768 ②.
    final confirmed = await _showVacationSummary(context, segments);
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(vacationFormProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Capture impact count before submit (impact preview may be null if user skipped it).
    final impactedCount = formState.impact?.impactedStudentCount ?? 0;
    final result = await notifier.submit();
    if (result != null && result.isNotEmpty) {
      if (!context.mounted) return;
      // A4 FE visibility: show how many students were notified (#929).
      await showDialog<void>(
        context: context,
        builder:
            (_) => NotebookAlertDialog(
              title: AppStrings.vacationNotifyDialogTitle,
              content: Text(AppStrings.vacationNotifyDialogBody(impactedCount)),
              confirmLabel: AppStrings.vacationNotifyDialogConfirm,
              onConfirm: () => Navigator.of(context).pop(),
            ),
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

  /// When true, past dates are not selectable (firstDate = today).
  final bool disablePast;

  const _DateRow({
    required this.label,
    required this.date,
    required this.onPick,
    this.disablePast = false,
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
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: disablePast ? today : DateTime(now.year - 1),
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

class _SubmitButton extends StatelessWidget {
  final VacationFormState state;
  final VoidCallback onSubmit;
  const _SubmitButton({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        state.canSubmit && !state.isSubmitting && !state.isLoadingImpact;
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

  /// Projected subscription auto-extension days for rollForward (#431 §5.3).
  /// Null when no valid range picked yet.
  final int? projectedExtensionDays;

  const _DispositionSection({
    required this.selected,
    required this.onChange,
    this.projectedExtensionDays,
  });

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
          studentHint: AppStrings.vacationDispositionMakeupCreditHint,
          isRecommended: true,
          groupValue: selected,
          onChange: onChange,
        ),
        _DispositionOption(
          value: VacationDisposition.freeCancel,
          label: AppStrings.vacationDispositionFreeCancelLabel,
          description: AppStrings.vacationDispositionFreeCancelDescription,
          studentHint: AppStrings.vacationDispositionFreeCancelHint,
          groupValue: selected,
          onChange: onChange,
        ),
        _DispositionOption(
          value: VacationDisposition.rollForward,
          label: AppStrings.vacationDispositionRollForwardLabel,
          description: AppStrings.vacationDispositionRollForwardDescription,
          studentHint: AppStrings.vacationDispositionRollForwardHint,
          groupValue: selected,
          onChange: onChange,
        ),
        // autoExtendedDays 예상치 — rollForward 선택 + 유효 기간일 때만 노출.
        if (selected == VacationDisposition.rollForward &&
            projectedExtensionDays != null)
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.space2,
              bottom: AppSpacing.space2,
            ),
            child: Text(
              AppStrings.vacationAutoExtendProjection(projectedExtensionDays!),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  /// One-line student-perspective explanation shown below [description].
  final String studentHint;

  final bool isRecommended;
  final ValueChanged<VacationDisposition> onChange;

  const _DispositionOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.description,
    required this.studentHint,
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
        child: Container(
          padding: EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
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
                            decoration: const BoxDecoration(
                              color: AppColors.paperAccent,
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
                    SizedBox(height: AppSpacing.space1),
                    // Student-perspective hint (#784).
                    Text(
                      studentHint,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                    if (isRecommended) ...[
                      SizedBox(height: AppSpacing.space1),
                      // Explain what "권장" means to the student (#784).
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: AppColors.inkTertiary,
                          ),
                          SizedBox(width: AppSpacing.space1),
                          Expanded(
                            child: Text(
                              AppStrings.vacationDispositionRecommendedHint,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
        final now = DateTime.now();
        final active = vacations
            .where((v) => v.isActiveOn(now))
            .toList(growable: false);
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(text: AppStrings.vacationActiveSection),
            SizedBox(height: AppSpacing.space2),
            ...active.map((v) => _ActiveVacationCard(period: v)),
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

// ──────────────────────────────────────────────────────────────
// Multi-segment widgets (#768 ②).
// ──────────────────────────────────────────────────────────────

class _AddedSegmentsSection extends StatelessWidget {
  final List<VacationSegment> segments;
  final void Function(int index) onRemove;
  const _AddedSegmentsSection({required this.segments, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(text: AppStrings.vacationAddedSegmentsSection),
        SizedBox(height: AppSpacing.space2),
        for (var i = 0; i < segments.length; i++)
          _AddedSegmentRow(segment: segments[i], onRemove: () => onRemove(i)),
      ],
    );
  }
}

class _AddedSegmentRow extends StatelessWidget {
  final VacationSegment segment;
  final VoidCallback onRemove;
  const _AddedSegmentRow({required this.segment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.space2),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
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
                    _shortDate(segment.startDate),
                    _shortDate(segment.endDate),
                  ),
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                ),
                SizedBox(height: 2),
                Text(
                  vacationDispositionLabel(segment.disposition),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: AppStrings.vacationSegmentRemoveTooltip,
            color: AppColors.inkTertiary,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddSegmentButton extends StatelessWidget {
  final VacationFormState state;
  final VoidCallback onAdd;
  const _AddSegmentButton({required this.state, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final canAdd = state.hasValidDraft && !state.draftOverlaps;
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.space2),
      child: OutlinedButton.icon(
        onPressed: canAdd ? onAdd : null,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(AppStrings.vacationSegmentAddButton),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.buttonHeight),
        ),
      ),
    );
  }
}

String _shortDate(DateTime d) => '${d.month}/${d.day}';

/// 최종 확인 요약 다이얼로그 — 등록될 구간별 기간 + 보상옵션을 나열한다 (#768 ②).
Future<bool?> _showVacationSummary(
  BuildContext context,
  List<VacationSegment> segments,
) {
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => NotebookAlertDialog(
          title: AppStrings.vacationSummaryTitle,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.vacationSummaryCount(segments.length),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.space2),
                for (final s in segments)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      AppStrings.vacationSummarySegmentLabel(
                        AppStrings.vacationCardDateRange(
                          _shortDate(s.startDate),
                          _shortDate(s.endDate),
                        ),
                        vacationDispositionLabel(s.disposition),
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          confirmLabel: AppStrings.vacationSummaryConfirm,
          cancelLabel: AppStrings.cancel,
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
        ),
  );
}
