import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../academy/domain/entities/academy_enums.dart';
import '../../../profile/domain/entities/cancellation_defaults.dart';
import '../../../profile/profile_facade.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

/// Per-subscription override screen for the 5 cancellation policy variables.
///
/// Spec: docs/specs/web/academy/teacher_cancellation_policy_spec.md §5.5
/// - ownership=teacher: writable (writer can override teacher defaults)
/// - ownership=academy: read-only (academy admin owns policy)
class SubscriptionPolicyOverrideScreen extends ConsumerStatefulWidget {
  final Subscription subscription;

  const SubscriptionPolicyOverrideScreen({
    super.key,
    required this.subscription,
  });

  @override
  ConsumerState<SubscriptionPolicyOverrideScreen> createState() =>
      _SubscriptionPolicyOverrideScreenState();
}

class _SubscriptionPolicyOverrideScreenState
    extends ConsumerState<SubscriptionPolicyOverrideScreen> {
  late int _deadlineHours;
  late bool _compensationEnabled;
  late bool _includeExtraMinutesText;
  late String _compensationMessage;
  late bool _notifyOwner;
  bool _isSaving = false;

  late final TextEditingController _messageController;
  late final TextEditingController _customHoursController;

  static const _presets = [4, 12, 24, 48];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _customHoursController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _customHoursController.dispose();
    super.dispose();
  }

  void _initFromDefaults(CancellationDefaults defaults) {
    final sub = widget.subscription;
    _deadlineHours =
        sub.overrideCancelDeadlineHours ?? defaults.cancellationDeadlineHours;
    _compensationEnabled =
        sub.overrideStudentCompensationExtraMinutesEnabled ??
        defaults.studentCompensationExtraMinutesEnabled;
    _includeExtraMinutesText =
        sub.overrideIncludeExtraMinutesTextOnLateCancel ??
        defaults.includeExtraMinutesTextOnLateCancel;
    _compensationMessage =
        sub.overrideStudentCompensationExtraMinutesMessage ??
        defaults.studentCompensationExtraMinutesMessage ??
        '';
    _notifyOwner =
        sub.overrideNotifyOwnerOnLateCancel ?? defaults.notifyOwnerOnLateCancel;

    _messageController.text = _compensationMessage;
    if (!_presets.contains(_deadlineHours)) {
      _customHoursController.text = _deadlineHours.toString();
    }
  }

  bool get _isAcademyOwned =>
      widget.subscription.ownership == SubscriptionOwnership.academy;

  Future<void> _save() async {
    if (_isSaving || _isAcademyOwned) return;
    setState(() => _isSaving = true);
    try {
      final sub = widget.subscription;
      final updated = sub.copyWith(
        overrideCancelDeadlineHours: _deadlineHours,
        overrideStudentCompensationExtraMinutesEnabled: _compensationEnabled,
        overrideIncludeExtraMinutesTextOnLateCancel: _includeExtraMinutesText,
        overrideStudentCompensationExtraMinutesMessage:
            _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
        clearOverrideStudentCompensationExtraMinutesMessage:
            _messageController.text.trim().isEmpty,
        overrideNotifyOwnerOnLateCancel: _notifyOwner,
      );
      await ref
          .read(subscriptionNotifierProvider(updated.studentId).notifier)
          .updateSubscription(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultsAsync = ref.watch(cancellationDefaultsNotifierProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(
        title: AppStrings.subscriptionPolicyOverrideTitle,
      ),
      body: defaultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                '$e',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ),
        data: (defaults) {
          _initFromDefaults(defaults);
          return _buildBody(defaults);
        },
      ),
    );
  }

  Widget _buildBody(CancellationDefaults defaults) {
    final readOnly = _isAcademyOwned;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority info banner — always shown (teacher or academy)
                  const _PolicyPriorityBanner(),
                  const SizedBox(height: AppSpacing.space4),

                  if (readOnly)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                      ),
                      child: Text(
                        AppStrings.subscriptionPolicyOverrideAcademyReadOnly,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.paperAccent,
                        ),
                      ),
                    ),

                  _DeadlineHoursField(
                    presets: _presets,
                    selected: _deadlineHours,
                    customController: _customHoursController,
                    defaultValue: defaults.cancellationDeadlineHours,
                    readOnly: readOnly,
                    onChanged: (h) => setState(() => _deadlineHours = h),
                  ),
                  const SizedBox(height: AppSpacing.space5),

                  _BoolToggleField(
                    label: AppStrings.policyCompensationCreditLabel,
                    helper: AppStrings.policyCompensationCreditHelper(
                      defaults.studentCompensationExtraMinutesEnabled,
                    ),
                    value: _compensationEnabled,
                    readOnly: readOnly,
                    onChanged: (v) => setState(() => _compensationEnabled = v),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  _BoolToggleField(
                    label: AppStrings.policyIncludeExtraMinutesTextLabel,
                    helper: AppStrings.policyIncludeExtraMinutesTextHelper(
                      defaults.includeExtraMinutesTextOnLateCancel,
                    ),
                    value: _includeExtraMinutesText,
                    readOnly: readOnly,
                    onChanged:
                        (v) => setState(() => _includeExtraMinutesText = v),
                  ),
                  const SizedBox(height: AppSpacing.space5),

                  _CompensationMessageField(
                    controller: _messageController,
                    defaultMessage:
                        defaults.studentCompensationExtraMinutesMessage,
                    readOnly: readOnly,
                  ),
                  const SizedBox(height: AppSpacing.space5),

                  if (_isAcademyOwned ||
                      widget.subscription.ownership ==
                          SubscriptionOwnership.academy)
                    _BoolToggleField(
                      label: AppStrings.policyNotifyOwnerLabel,
                      helper: AppStrings.policyNotifyOwnerHelper(
                        defaults.notifyOwnerOnLateCancel,
                      ),
                      value: _notifyOwner,
                      readOnly: readOnly,
                      onChanged: (v) => setState(() => _notifyOwner = v),
                    ),

                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppStrings.subscriptionPolicyOverrideFooter,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: SizedBox(
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
                  onPressed: _isSaving ? null : _save,
                  child:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(AppStrings.save),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Banner shown at the top of the policy override screen.
/// Informs the teacher that values originate from global defaults
/// and that priority order is: individual > template > global.
class _PolicyPriorityBanner extends StatelessWidget {
  const _PolicyPriorityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccentSelected),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.policySourceNotice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.policyPriorityNotice,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineHoursField extends StatefulWidget {
  final List<int> presets;
  final int selected;
  final TextEditingController customController;
  final int defaultValue;
  final bool readOnly;
  final ValueChanged<int> onChanged;

  const _DeadlineHoursField({
    required this.presets,
    required this.selected,
    required this.customController,
    required this.defaultValue,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  State<_DeadlineHoursField> createState() => _DeadlineHoursFieldState();
}

class _DeadlineHoursFieldState extends State<_DeadlineHoursField> {
  late bool _isCustom;

  @override
  void initState() {
    super.initState();
    _isCustom = !widget.presets.contains(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.rescheduleDeadlineLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.policyDeadlineHoursHelper(widget.defaultValue),
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          children: [
            ...widget.presets.map(
              (h) => ChoiceChip(
                label: Text('$h${AppStrings.hourSuffix}'),
                selected: !_isCustom && widget.selected == h,
                onSelected:
                    widget.readOnly
                        ? null
                        : (_) {
                          setState(() => _isCustom = false);
                          widget.onChanged(h);
                        },
                selectedColor: AppColors.paperAccent,
                labelStyle: AppTypography.bodySmall.copyWith(
                  color:
                      (!_isCustom && widget.selected == h)
                          ? AppColors.paper
                          : AppColors.ink,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            ChoiceChip(
              label: const Text(
                AppStrings.unifiedSubscriptionDirectInputToggle,
              ),
              selected: _isCustom,
              onSelected:
                  widget.readOnly
                      ? null
                      : (_) => setState(() => _isCustom = true),
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
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: widget.customController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !widget.readOnly,
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) widget.onChanged(n);
            },
            decoration: InputDecoration(
              suffixText: AppStrings.hourSuffix,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
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
      ],
    );
  }
}

class _BoolToggleField extends StatelessWidget {
  final String label;
  final String helper;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  const _BoolToggleField({
    required this.label,
    required this.helper,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                helper,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: readOnly ? null : onChanged,
          activeThumbColor: AppColors.paperAccent,
        ),
      ],
    );
  }
}

class _CompensationMessageField extends StatelessWidget {
  final TextEditingController controller;
  final String? defaultMessage;
  final bool readOnly;

  const _CompensationMessageField({
    required this.controller,
    required this.defaultMessage,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.policyCompensationMessageLabel,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          AppStrings.policyCompensationMessageHelper(defaultMessage),
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: controller,
          enabled: !readOnly,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                defaultMessage ?? AppStrings.policyCompensationMessageHint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.paperAccent, width: 1.5),
            ),
          ),
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}
