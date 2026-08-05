import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../../subscription/subscription_facade.dart' show Subscription;

/// §2.6.2 trigger — the S3 sheet interrupts the save only for an exhausted
/// subscription on a single lesson. S1/S2 (remaining > 0) and the recurring
/// path keep the existing zero-extra-tap save (regression contract, AC-2.2).
bool shouldPromptOverflowMode({
  required Subscription? subscription,
  required bool isRecurring,
}) =>
    !isRecurring &&
    subscription != null &&
    (subscription.remainingLessons ?? 1) <= 0;

/// §2.6.3 known edge ② — dismissing the 2+ subscription picker leaves the
/// save without an attribution, which reaches the BE legacy silent-bonus
/// expansion (the S3 sheet never fires on a null subscription). With active
/// subscriptions present, the save must re-prompt for a pick instead.
/// Zero actives (trial auto-issue) and the recurring path stay untouched.
bool mustPickSubscriptionBeforeSave({
  required Subscription? selected,
  required List<Subscription> actives,
  required bool isRecurring,
}) => !isRecurring && selected == null && actives.isNotEmpty;

/// §2.6.3 renewal continuation route. The preview lesson id rides along so the
/// issue screen can delete the orphan when the teacher leaves without issuing
/// (known edge ① — the add-lesson caller is gone after pushReplacement).
String renewalIssueLocation({
  required String studentId,
  required String previewLessonId,
}) =>
    '${AppRoutes.issueSubscription}?studentId=$studentId'
    '&previewLessonId=$previewLessonId';

/// How to account for a lesson on an exhausted subscription
/// (subscription_required_spec §2.6.2 — wire values of `overflow_mode`).
enum LessonOverflowChoice {
  /// Consume one makeup credit (S4 path, `makeup_credit`).
  makeupCredit,

  /// Free bonus session on the subscription (`bonus`).
  bonus,

  /// Preview lesson + renewal proposal (`renewal_pending`).
  renewalProposal,

  /// Unconnected student — preview lesson + direct renewal issuance
  /// (`renewal_pending`, then route to the issue screen).
  renewalIssue,
}

extension LessonOverflowChoiceWire on LessonOverflowChoice {
  /// BE `LessonCreate.overflow_mode` value.
  String get wireValue => switch (this) {
    LessonOverflowChoice.makeupCredit => 'makeup_credit',
    LessonOverflowChoice.bonus => 'bonus',
    LessonOverflowChoice.renewalProposal => 'renewal_pending',
    LessonOverflowChoice.renewalIssue => 'renewal_pending',
  };
}

/// Show the S3 sheet — pick how to handle a lesson on a 0-remaining
/// subscription. Returns null when dismissed (save is aborted by the caller).
///
/// - [availableCredits] > 0 exposes the makeup-credit option.
/// - [isConnectedStudent] false swaps the renewal proposal for direct
///   issuance (§2.7 — unconnected students can't receive proposals).
/// - [allowRenewal] false hides renewal entirely (record mode — a completed
///   past lesson can't wait for a renewal).
Future<LessonOverflowChoice?> showLessonOverflowModeSheet({
  required BuildContext context,
  required String studentName,
  required String subscriptionName,
  required int availableCredits,
  required bool isConnectedStudent,
  bool allowRenewal = true,
}) {
  final options = <LessonOverflowChoice>[
    if (availableCredits > 0) LessonOverflowChoice.makeupCredit,
    LessonOverflowChoice.bonus,
    if (allowRenewal)
      isConnectedStudent
          ? LessonOverflowChoice.renewalProposal
          : LessonOverflowChoice.renewalIssue,
  ];
  // D1 — renewal is the recommended default (bonus giveaways erode revenue);
  // without renewal (record mode) fall back to bonus.
  final recommended =
      allowRenewal
          ? (isConnectedStudent
              ? LessonOverflowChoice.renewalProposal
              : LessonOverflowChoice.renewalIssue)
          : LessonOverflowChoice.bonus;

  return showNotebookBottomSheet<LessonOverflowChoice>(
    context: context,
    isScrollControlled: true,
    builder:
        (ctx) => LessonOverflowModeSheet(
          studentName: studentName,
          subscriptionName: subscriptionName,
          availableCredits: availableCredits,
          options: options,
          recommended: recommended,
          onSelected: (choice) => Navigator.of(ctx).pop(choice),
        ),
  );
}

/// Option list shown inside the S3 bottom sheet.
class LessonOverflowModeSheet extends StatefulWidget {
  const LessonOverflowModeSheet({
    super.key,
    required this.studentName,
    required this.subscriptionName,
    required this.availableCredits,
    required this.options,
    required this.recommended,
    required this.onSelected,
  });

  final String studentName;
  final String subscriptionName;
  final int availableCredits;
  final List<LessonOverflowChoice> options;
  final LessonOverflowChoice recommended;
  final ValueChanged<LessonOverflowChoice> onSelected;

  @override
  State<LessonOverflowModeSheet> createState() =>
      _LessonOverflowModeSheetState();
}

class _LessonOverflowModeSheetState extends State<LessonOverflowModeSheet> {
  late LessonOverflowChoice _selected = widget.recommended;

  String _label(LessonOverflowChoice choice) => switch (choice) {
    LessonOverflowChoice.makeupCredit => AppStrings.overflowOptionMakeup,
    LessonOverflowChoice.bonus => AppStrings.overflowOptionBonus,
    LessonOverflowChoice.renewalProposal => AppStrings.overflowOptionRenewal,
    LessonOverflowChoice.renewalIssue => AppStrings.overflowOptionRenewalIssue,
  };

  String _description(LessonOverflowChoice choice) => switch (choice) {
    LessonOverflowChoice.makeupCredit => AppStrings.overflowOptionMakeupDesc(
      widget.availableCredits,
    ),
    LessonOverflowChoice.bonus => AppStrings.overflowOptionBonusDesc,
    LessonOverflowChoice.renewalProposal =>
      AppStrings.overflowOptionRenewalDesc,
    LessonOverflowChoice.renewalIssue =>
      AppStrings.overflowOptionRenewalIssueDesc,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.overflowSheetTitle,
          style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.overflowSheetSubtitle(
            widget.studentName,
            widget.subscriptionName,
          ),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        ...widget.options.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: _OverflowOptionCard(
              label: _label(choice),
              description: _description(choice),
              selected: choice == _selected,
              onTap: () => setState(() => _selected = choice),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.buttonHeight,
          child: FilledButton(
            onPressed: () => widget.onSelected(_selected),
            child: const Text(AppStrings.continueAction),
          ),
        ),
      ],
    );
  }
}

class _OverflowOptionCard extends StatelessWidget {
  const _OverflowOptionCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? AppColors.paperAccent : AppColors.inkTertiary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
