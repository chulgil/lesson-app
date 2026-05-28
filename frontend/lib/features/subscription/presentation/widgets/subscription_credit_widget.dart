import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../domain/entities/subscription.dart';

/// Displays student cancellation credits accumulated per subscription (G17).
///
/// Shown on subscription cards: "변경권 잔여: N회".
/// Earned when teacher cancels within 12h (deadline violation),
/// consumed when student reschedules/cancels.
class SubscriptionCreditWidget extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionCreditWidget({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final count = subscription.cancellationCredits;
    final hasCredits = count > 0;

    final fg = hasCredits ? AppColors.paperAccent : AppColors.inkTertiary;
    final label =
        hasCredits
            ? AppStrings.cancellationCreditRemaining(count)
            : AppStrings.cancellationCreditNone;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          NotebookGlyph.check,
          style: AppTypography.bodySmall.copyWith(color: fg),
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: fg,
            fontWeight: hasCredits ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
