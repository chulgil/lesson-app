import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/makeup_credit.dart';

/// Booking payment source for a single lesson reservation (#432 §5.1).
enum BookingPaymentSource {
  /// Deduct from the regular subscription.
  regularSubscription,

  /// Spend one makeup credit.
  makeupCredit,
}

/// Booking-time "use makeup credit" selector (#432 §5.1 / §5.2).
///
/// Shows two radio-style options. When the student has no spendable credit the
/// credit option is hidden entirely (only regular is shown), matching the
/// default-priority table in §5.2.
class MakeupCreditUseSelector extends StatelessWidget {
  /// Spendable balance (not used, not expired).
  final MakeupCreditBalance balance;

  /// Remaining regular lessons, or null when unknown/unlimited.
  final int? regularRemaining;

  /// Total regular lessons for the "x/y회" label, or null.
  final int? regularTotal;

  final BookingPaymentSource selected;
  final ValueChanged<BookingPaymentSource> onChanged;

  const MakeupCreditUseSelector({
    super.key,
    required this.balance,
    required this.selected,
    required this.onChanged,
    this.regularRemaining,
    this.regularTotal,
  });

  @override
  Widget build(BuildContext context) {
    final hasCredit = balance.hasAny;
    // When the credit option is hidden, a stale makeupCredit selection must not
    // linger upstream. Surface regularSubscription as the effective source and
    // notify the parent once after this frame so its state stays valid.
    final effectiveSelected = (!hasCredit && selected == BookingPaymentSource.makeupCredit)
        ? BookingPaymentSource.regularSubscription
        : selected;
    if (effectiveSelected != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(BookingPaymentSource.regularSubscription);
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Option(
          isSelected:
              effectiveSelected == BookingPaymentSource.regularSubscription,
          title: AppStrings.makeupCreditUseRegularLabel,
          subtitle: (regularRemaining != null && regularTotal != null)
              ? AppStrings.makeupCreditRegularRemaining(
                  regularRemaining!,
                  regularTotal!,
                )
              : null,
          onTap: () => onChanged(BookingPaymentSource.regularSubscription),
        ),
        if (hasCredit) ...[
          const SizedBox(height: AppSpacing.space2),
          _Option(
            isSelected: effectiveSelected == BookingPaymentSource.makeupCredit,
            title: AppStrings.makeupCreditUseCreditLabel,
            subtitle: AppStrings.makeupCreditUseCreditSubtitle(
              balance.availableCount,
              _expiryLabel(balance),
            ),
            onTap: () => onChanged(BookingPaymentSource.makeupCredit),
          ),
        ],
      ],
    );
  }

  static String _expiryLabel(MakeupCreditBalance balance) {
    final expiry = balance.earliestExpiry;
    return expiry == null ? '-' : formatDateMD(expiry);
  }
}

class _Option extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.isSelected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom radio indicator (avoids deprecated Material Radio API).
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.paperAccent
                      : AppColors.inkTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
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
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
