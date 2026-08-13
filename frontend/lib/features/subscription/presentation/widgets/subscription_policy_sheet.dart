import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/lesson_policy_visuals.dart';
import '../providers/lesson_policy_providers.dart';
import '../providers/subscription_providers.dart';
import '../screens/subscription_policy_override_screen.dart';
import 'add_reschedule_sheet.dart';
import 'change_location_sheet.dart';
import 'edit_cancel_deadline_sheet.dart';
import 'edit_travel_time_sheet.dart';

/// Bottom sheet showing the applied policy for a subscription.
///
/// When [viewerRole] == 'teacher', editable buttons appear for post-issuance
/// fields (reschedule credits, location, travel time, cancel deadline).
/// Fields that require re-issuance (lesson count, amount) are shown as
/// read-only in a separate non-editable section.
class SubscriptionPolicySheet extends ConsumerWidget {
  final Subscription subscription;

  /// 'teacher' shows edit buttons; any other value is read-only.
  final String viewerRole;

  /// Callback invoked after teacher navigates to issue a new subscription.
  final VoidCallback? onIssueNewSubscription;

  /// The student's preferred location type from their lesson request.
  /// When the teacher changes the location to a different type, a confirmation
  /// dialog is shown informing them of the student's original preference.
  final LocationType? preferredLocationType;

  const SubscriptionPolicySheet({
    super.key,
    required this.subscription,
    this.viewerRole = 'student',
    this.onIssueNewSubscription,
    this.preferredLocationType,
  });

  static Future<void> show(
    BuildContext context, {
    required Subscription subscription,
    String viewerRole = 'student',
    VoidCallback? onIssueNewSubscription,
    LocationType? preferredLocationType,
  }) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: viewerRole == 'teacher' ? 0.65 : 0.45,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder:
                (ctx, scrollController) => _SheetFrame(
                  scrollController: scrollController,
                  child: SubscriptionPolicySheet(
                    subscription: subscription,
                    viewerRole: viewerRole,
                    onIssueNewSubscription: onIssueNewSubscription,
                    preferredLocationType: preferredLocationType,
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(
      membershipProvider(subscription.membershipId),
    );

    return membershipAsync.when(
      loading: () => const _Loading(),
      error:
          (_, __) => _buildBody(context, ref, policy: null, membership: null),
      data: (membership) {
        if (membership == null) {
          return _buildBody(context, ref, policy: null, membership: null);
        }
        final lessonClassAsync = ref.watch(
          lessonClassProvider(membership.lessonClassId),
        );
        return lessonClassAsync.when(
          loading: () => const _Loading(),
          error:
              (_, __) => _buildBody(
                context,
                ref,
                policy: null,
                membership: membership,
              ),
          data: (lessonClass) {
            if (lessonClass == null) {
              return _buildBody(
                context,
                ref,
                policy: null,
                membership: membership,
              );
            }
            final policyAsync = ref.watch(
              effectivePolicyProvider(
                teacherId: lessonClass.teacherId,
                lessonClassId: membership.lessonClassId,
              ),
            );
            return policyAsync.when(
              loading: () => const _Loading(),
              error:
                  (_, __) => _buildBody(
                    context,
                    ref,
                    policy: null,
                    membership: membership,
                  ),
              data:
                  (policy) => _buildBody(
                    context,
                    ref,
                    policy: policy,
                    membership: membership,
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required LessonPolicy? policy,
    required ClassMembership? membership,
  }) {
    final isTeacher = viewerRole == 'teacher';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.rule_rounded, size: 20, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            Text(
              AppStrings.policyAppliedTitle,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Editable fields (teacher) or read-only policy rows (student)
        if (isTeacher && membership != null)
          _EditableSection(
            subscription: subscription,
            membership: membership,
            policy: policy,
            onIssueNewSubscription: onIssueNewSubscription,
            preferredLocationType: preferredLocationType,
          )
        else ...[
          _buildReadOnlyPolicyRows(policy),
        ],

        const SizedBox(height: AppSpacing.space3),
        Text(
          AppStrings.policyAppliedFooter,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _buildReadOnlyPolicyRows(LessonPolicy? policy) {
    final remaining = subscription.remainingReschedule;
    final total = subscription.effectiveRescheduleAllowance;
    final deadline = subscription.effectiveCancelDeadlineHours;
    final changeLine = AppStrings.policyChangeSummary(
      deadlineHours: deadline,
      totalAllowance: total,
      remaining: remaining,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyItem(
          label: AppStrings.policyChangeCancelLabel,
          value: changeLine,
          valueColor: remaining <= 1 ? AppColors.paperAccent : null,
        ),
        if (policy != null) ...[
          _PolicyItem(
            label: AppStrings.policyNoShowLabel,
            value: policy.noShowPolicySummary,
          ),
          _PolicyItem(
            label: AppStrings.policyCarryoverLabel,
            value: policy.carryoverPolicySummary,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editable section — teacher only
// ---------------------------------------------------------------------------

class _EditableSection extends ConsumerStatefulWidget {
  final Subscription subscription;
  final ClassMembership membership;
  final LessonPolicy? policy;
  final VoidCallback? onIssueNewSubscription;
  final LocationType? preferredLocationType;

  const _EditableSection({
    required this.subscription,
    required this.membership,
    required this.policy,
    this.onIssueNewSubscription,
    this.preferredLocationType,
  });

  @override
  ConsumerState<_EditableSection> createState() => _EditableSectionState();
}

class _EditableSectionState extends ConsumerState<_EditableSection> {
  bool _isSaving = false;

  Future<void> _updateSubscription(Subscription updated) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(subscriptionNotifierProvider(updated.studentId).notifier)
          .updateSubscription(updated);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateMembership(ClassMembership updated) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(membershipNotifierProvider(updated.lessonClassId).notifier)
          .updateMembership(updated);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final membership = widget.membership;
    final remaining = sub.remainingReschedule;
    final total = sub.effectiveRescheduleAllowance;
    final deadline = sub.effectiveCancelDeadlineHours;

    // Location display label
    final locationId = membership.lessonLocationId;
    final locationAsync =
        locationId != null ? ref.watch(locationProvider(locationId)) : null;
    final locationLabel =
        locationAsync?.when(
          data: (loc) => loc?.name ?? AppStrings.locationStudentHomeLabel,
          loading: () => '...',
          error: (_, __) => '-',
        ) ??
        '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 변경/취소권 ──
        _EditableRow(
          label: AppStrings.policyChangeCancelLabel,
          value: '$remaining/$total회',
          valueColor: remaining <= 1 ? AppColors.paperAccent : null,
          buttonLabel: '+ 추가',
          isSaving: _isSaving,
          onTap: () => _showAddRescheduleSheet(context, sub),
        ),

        // ── 레슨 장소 ──
        _EditableRow(
          label: AppStrings.locationLabel,
          value: locationLabel,
          buttonLabel: AppStrings.changeLocation,
          isSaving: _isSaving,
          onTap: () => _showChangeLocationSheet(context, membership),
        ),

        // ── 이동시간 ──
        _EditableRow(
          label: AppStrings.travelTimeLabel,
          value: '${membership.travelTimeMinutes}분',
          buttonLabel: AppStrings.edit,
          isSaving: _isSaving,
          onTap: () => _showEditTravelTimeSheet(context, membership),
        ),

        // ── 취소 기준시간 ──
        _EditableRow(
          label: AppStrings.rescheduleDeadlineLabel,
          value: '$deadline${AppStrings.hourSuffix} 전',
          buttonLabel: AppStrings.edit,
          isSaving: _isSaving,
          onTap: () => _showEditCancelDeadlineSheet(context, sub),
        ),

        // ── 추가 정책 (보상·알림·문구) ──
        _EditableRow(
          label: AppStrings.subscriptionPolicyOverrideTitle,
          value: _compensationSummary(sub),
          buttonLabel: AppStrings.edit,
          isSaving: _isSaving,
          onTap: () => _openOverrideScreen(context, sub),
        ),

        const SizedBox(height: AppSpacing.space4),

        // ── 수정 불가 섹션 구분선 ──
        _NotEditableDivider(),

        const SizedBox(height: AppSpacing.space3),

        // Non-editable fields
        _PolicyItem(
          label: AppStrings.lessonCountLabel,
          value: '${sub.totalLessonsForDisplay ?? '-'}회',
          isGrey: true,
        ),
        _PolicyItem(
          label: AppStrings.amountLabel,
          value: '${_formatAmount(sub.amount)}원',
          isGrey: true,
        ),
        if (sub.endDate != null)
          _PolicyItem(
            label: AppStrings.validityLabel,
            value: _formatDate(sub.endDate!),
            isGrey: true,
          ),

        const SizedBox(height: AppSpacing.space3),

        // Footer: issue new subscription link
        Text(
          AppStrings.subscriptionEditNewRequired,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space1),
        GestureDetector(
          onTap: widget.onIssueNewSubscription,
          // H6 — 버튼 없이 글자만 눌리는 링크라 밑줄로 affordance 를 준다.
          child: Text(
            '${AppStrings.issueNewSubscription} →',
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.paperAccent,
            ),
          ),
        ),
      ],
    );
  }

  // --------------- bottom sheets ---------------

  void _showAddRescheduleSheet(BuildContext context, Subscription sub) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => AddRescheduleSheet(
            subscription: sub,
            onConfirm: (count) async {
              final updated = sub.copyWith(
                bonusRescheduleCount: sub.bonusRescheduleCount + count,
              );
              await _updateSubscription(updated);
            },
          ),
    );
  }

  void _showChangeLocationSheet(
    BuildContext context,
    ClassMembership membership,
  ) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => ChangeLocationSheet(
            membership: membership,
            preferredLocationType: widget.preferredLocationType,
            onSave: (locationId, travelTime) async {
              final updated = membership.copyWith(
                lessonLocationId: locationId,
                travelTimeMinutes: travelTime,
              );
              await _updateMembership(updated);
            },
          ),
    );
  }

  void _showEditTravelTimeSheet(
    BuildContext context,
    ClassMembership membership,
  ) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => EditTravelTimeSheet(
            currentMinutes: membership.travelTimeMinutes,
            onSave: (minutes) async {
              final updated = membership.copyWith(travelTimeMinutes: minutes);
              await _updateMembership(updated);
            },
          ),
    );
  }

  void _showEditCancelDeadlineSheet(BuildContext context, Subscription sub) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => EditCancelDeadlineSheet(
            currentHours: sub.effectiveCancelDeadlineHours,
            onSave: (hours) async {
              final updated = sub.copyWith(overrideCancelDeadlineHours: hours);
              await _updateSubscription(updated);
            },
          ),
    );
  }

  String _compensationSummary(Subscription sub) {
    final hasOverrides =
        sub.overrideStudentCompensationExtraMinutesEnabled != null ||
        sub.overrideIncludeExtraMinutesTextOnLateCancel != null ||
        sub.overrideStudentCompensationExtraMinutesMessage != null ||
        sub.overrideNotifyOwnerOnLateCancel != null ||
        sub.overrideCancelDeadlineHours != null;
    return hasOverrides
        ? AppStrings.subscriptionPolicyOverridden
        : AppStrings.subscriptionPolicyUsingDefault;
  }

  void _openOverrideScreen(BuildContext context, Subscription sub) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionPolicyOverrideScreen(subscription: sub),
      ),
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SheetFrame extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;

  const _SheetFrame({required this.child, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space2),
            child: BottomSheetHandle(margin: EdgeInsets.zero),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Read-only policy row (used in student view and non-editable section).
class _PolicyItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isGrey;

  const _PolicyItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isGrey = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseTextStyle = AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: baseTextStyle.copyWith(
                color: isGrey ? AppColors.inkTertiary : AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: baseTextStyle.copyWith(
                color:
                    isGrey
                        ? AppColors.inkTertiary
                        : (valueColor ?? AppColors.ink),
                fontWeight: isGrey ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable policy row with a button on the right (teacher view).
class _EditableRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool isSaving;

  const _EditableRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.buttonLabel,
    required this.onTap,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperAccent,
              minimumSize: Size(0, AppSpacing.buttonHeightSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: isSaving ? null : onTap,
            child: Text(
              buttonLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section divider showing "수정 불가 (재발급 필요)".
class _NotEditableDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AppColors.inkQuaternary)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          child: Text(
            AppStrings.subscriptionEditNotEditable,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: AppColors.inkQuaternary)),
      ],
    );
  }
}
