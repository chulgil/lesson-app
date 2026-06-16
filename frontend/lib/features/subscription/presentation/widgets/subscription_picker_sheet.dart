import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../domain/entities/subscription.dart';
import '../extensions/subscription_visuals.dart';

/// Show the subscription picker for a manually-added lesson (spec §2.5).
///
/// Used when a student has 2+ active subscriptions and the teacher must choose
/// which one this lesson is deducted from. Returns the chosen [Subscription],
/// or null if the sheet is dismissed without choosing.
Future<Subscription?> showSubscriptionPickerSheet({
  required BuildContext context,
  required List<Subscription> subscriptions,
  String? recommendedId,
}) {
  return showNotebookBottomSheet<Subscription>(
    context: context,
    isScrollControlled: true,
    builder:
        (ctx) => SubscriptionPickerSheet(
          subscriptions: subscriptions,
          recommendedId: recommendedId,
          onSelected: (sub) => Navigator.of(ctx).pop(sub),
        ),
  );
}

/// Selection list shown inside the picker bottom sheet.
class SubscriptionPickerSheet extends StatelessWidget {
  const SubscriptionPickerSheet({
    super.key,
    required this.subscriptions,
    required this.onSelected,
    this.recommendedId,
  });

  final List<Subscription> subscriptions;
  final ValueChanged<Subscription> onSelected;
  final String? recommendedId;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.manualLessonPickerTitle,
          style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.manualLessonPickerSubtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: subscriptions.length,
            separatorBuilder:
                (_, __) => const SizedBox(height: AppSpacing.space3),
            itemBuilder: (_, index) {
              final sub = subscriptions[index];
              return SubscriptionPickerCard(
                subscription: sub,
                recommended: sub.id == recommendedId,
                onTap: () => onSelected(sub),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Single selectable subscription card inside the picker.
class SubscriptionPickerCard extends StatelessWidget {
  const SubscriptionPickerCard({
    super.key,
    required this.subscription,
    required this.onTap,
    this.recommended = false,
  });

  final Subscription subscription;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final instrument = subscription.instrument;
    final hasInstrument = instrument != null && instrument.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(
            color:
                recommended ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: recommended ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasInstrument) ...[
                  _InstrumentChip(instrument: instrument),
                  const SizedBox(width: AppSpacing.space2),
                ],
                Expanded(
                  child: Text(
                    subscription.typeLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (recommended) const _RecommendedBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              subscription.summaryText,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({required this.instrument});

  final String instrument;

  @override
  Widget build(BuildContext context) {
    final pair = InstrumentColors.getColor(instrument);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        border: Border.all(color: pair.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        instrument,
        style: AppTypography.captionSmall.copyWith(
          color: pair.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Text(
        AppStrings.manualLessonPickerRecommendedBadge,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
