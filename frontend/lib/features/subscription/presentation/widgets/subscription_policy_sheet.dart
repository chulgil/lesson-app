import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/lesson_policy_visuals.dart';
import '../providers/lesson_policy_providers.dart';
import '../providers/subscription_providers.dart';
import 'location_travel_selector.dart';

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
          child: Text(
            '${AppStrings.issueNewSubscription} →',
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
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
          (ctx) => _AddRescheduleSheet(
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
          (ctx) => _ChangeLocationSheet(
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
          (ctx) => _EditTravelTimeSheet(
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
          (ctx) => _EditCancelDeadlineSheet(
            currentHours: sub.effectiveCancelDeadlineHours,
            onSave: (hours) async {
              final updated = sub.copyWith(overrideCancelDeadlineHours: hours);
              await _updateSubscription(updated);
            },
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
// Add Reschedule Credits Sheet
// ---------------------------------------------------------------------------

class _AddRescheduleSheet extends StatefulWidget {
  final Subscription subscription;
  final Future<void> Function(int count) onConfirm;

  const _AddRescheduleSheet({
    required this.subscription,
    required this.onConfirm,
  });

  @override
  State<_AddRescheduleSheet> createState() => _AddRescheduleSheetState();
}

class _AddRescheduleSheetState extends State<_AddRescheduleSheet> {
  int _count = 1;
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.addRescheduleCredit,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Count row
          Row(
            children: [
              Text(
                AppStrings.additionalCount,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _CounterButton(
                value: _count,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _count = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),

          // Reason field
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: AppStrings.addReason,
              hintText: '예: 이사 관련 일정 변경',
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppColors.paperAccent,
                  width: 1.5,
                ),
              ),
            ),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed:
                  _saving
                      ? null
                      : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onConfirm(_count);
                          if (context.mounted) Navigator.of(context).pop();
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text('$_count회 추가'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change Location Sheet
// ---------------------------------------------------------------------------

class _ChangeLocationSheet extends ConsumerStatefulWidget {
  final ClassMembership membership;
  final Future<void> Function(String? locationId, int travelTime) onSave;

  /// Student's preferred location type from their original lesson request.
  /// When the teacher picks a different type, a confirmation dialog is shown.
  final LocationType? preferredLocationType;

  const _ChangeLocationSheet({
    required this.membership,
    required this.onSave,
    this.preferredLocationType,
  });

  @override
  ConsumerState<_ChangeLocationSheet> createState() =>
      _ChangeLocationSheetState();
}

class _ChangeLocationSheetState extends ConsumerState<_ChangeLocationSheet> {
  late String? _locationId;
  late int _travelTime;
  LocationType? _selectedLocationType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locationId = widget.membership.lessonLocationId;
    _travelTime = widget.membership.travelTimeMinutes;
  }

  /// Returns a human-readable label for [type].
  String _locationTypeLabel(LocationType type) {
    switch (type) {
      case LocationType.studentHome:
        return AppStrings.locationStudentHomeLabel;
      case LocationType.externalPlace:
        return AppStrings.locationExternalPlaceLabel;
      case LocationType.teacherStudio:
        return AppStrings.locationTeacherHomeLabel;
      case LocationType.online:
        return AppStrings.locationOnlineLabel;
      case LocationType.academyRoom:
        return AppStrings.academy;
    }
  }

  Future<void> _handleSave() async {
    final preferred = widget.preferredLocationType;

    // Show warning dialog if the selected type differs from student's preference
    if (preferred != null &&
        _selectedLocationType != null &&
        _selectedLocationType != preferred) {
      final confirmed = await showNotebookDialog<bool>(
        context: context,
        title: AppStrings.locationChangeWarningTitle,
        content: Text(
          AppStrings.locationChangeWarningBody(
            _locationTypeLabel(preferred),
            _locationTypeLabel(_selectedLocationType!),
          ),
        ),
        confirmLabel: AppStrings.changeTypeLabel,
        cancelLabel: AppStrings.cancel,
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(_locationId, _travelTime);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.changeLocation,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          LocationTravelSelector(
            membershipId: widget.membership.id,
            studentId: widget.membership.studentId,
            currentLocationId: _locationId,
            currentTravelTime: _travelTime,
            onLocationChanged: (id) => setState(() => _locationId = id),
            onTravelTimeChanged: (t) => setState(() => _travelTime = t),
            onLocationTypeChanged:
                (type) => setState(() => _selectedLocationType = type),
          ),
          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: _saving ? null : _handleSave,
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Travel Time Sheet
// ---------------------------------------------------------------------------

class _EditTravelTimeSheet extends StatefulWidget {
  final int currentMinutes;
  final Future<void> Function(int minutes) onSave;

  const _EditTravelTimeSheet({
    required this.currentMinutes,
    required this.onSave,
  });

  @override
  State<_EditTravelTimeSheet> createState() => _EditTravelTimeSheetState();
}

class _EditTravelTimeSheetState extends State<_EditTravelTimeSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentMinutes.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.editTravelTime,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: AppStrings.travelTimeMinutesSuffix,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppColors.paperAccent,
                  width: 1.5,
                ),
              ),
            ),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed:
                  _saving
                      ? null
                      : () async {
                        final minutes = int.tryParse(_controller.text) ?? 0;
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(minutes);
                          if (context.mounted) Navigator.of(context).pop();
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Cancel Deadline Sheet
// ---------------------------------------------------------------------------

class _EditCancelDeadlineSheet extends StatefulWidget {
  final int currentHours;
  final Future<void> Function(int hours) onSave;

  const _EditCancelDeadlineSheet({
    required this.currentHours,
    required this.onSave,
  });

  @override
  State<_EditCancelDeadlineSheet> createState() =>
      _EditCancelDeadlineSheetState();
}

class _EditCancelDeadlineSheetState extends State<_EditCancelDeadlineSheet> {
  static const _presets = [4, 12, 24, 48];
  late int _selected;
  late final TextEditingController _customController;
  bool _isCustom = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentHours;
    _isCustom = !_presets.contains(widget.currentHours);
    _customController = TextEditingController(
      text: _isCustom ? widget.currentHours.toString() : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int get _effectiveHours =>
      _isCustom
          ? (int.tryParse(_customController.text) ?? _selected)
          : _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space5,
        right: AppSpacing.space5,
        top: AppSpacing.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.editCancelDeadline,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Preset chips
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              ..._presets.map(
                (h) => ChoiceChip(
                  label: Text('$h시간'),
                  selected: !_isCustom && _selected == h,
                  onSelected: (_) {
                    setState(() {
                      _selected = h;
                      _isCustom = false;
                    });
                  },
                  selectedColor: AppColors.paperAccent,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color:
                        (!_isCustom && _selected == h)
                            ? AppColors.paper
                            : AppColors.ink,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text(AppStrings.unifiedSubscriptionDirectInputToggle),
                selected: _isCustom,
                onSelected: (_) => setState(() => _isCustom = true),
                selectedColor: AppColors.paperAccent,
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: _isCustom ? AppColors.paper : AppColors.ink,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ],
          ),

          if (_isCustom) ...[
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                suffixText: AppStrings.hourSuffix,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: AppColors.paperAccent,
                    width: 1.5,
                  ),
                ),
              ),
              style: AppTypography.bodyMedium,
            ),
          ],

          const SizedBox(height: AppSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
                minimumSize: Size(0, AppSpacing.buttonHeight),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed:
                  _saving
                      ? null
                      : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onSave(_effectiveHours);
                          if (context.mounted) Navigator.of(context).pop();
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
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
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.inkQuaternary),
            ),
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

/// Simple +/- counter button for number inputs.
class _CounterButton extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterButton({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size(32, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
