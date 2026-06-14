import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/makeup_credit.dart';
import '../extensions/makeup_credit_visuals.dart';
import '../providers/makeup_credit_providers.dart';

/// Student-side makeup credit card (#432 §9.1).
///
/// Shows the spendable balance, earliest expiry, and a short ledger.
/// Renders nothing when the student has no credit history.
class MakeupCreditCard extends ConsumerWidget {
  const MakeupCreditCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(studentMakeupCreditsProvider);
    return creditsAsync.when(
      data: (credits) {
        if (credits.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        final balance = MakeupCreditBalance.fromCredits(credits, now);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.makeupCreditTitle,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.makeupCreditBalanceLabel(balance.availableCount),
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (balance.earliestExpiry != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.makeupCreditEarliestExpiry(
                    formatDateMD(balance.earliestExpiry!),
                    _dDay(now, balance.earliestExpiry!),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              Text(
                AppStrings.makeupCreditHistoryHeader(credits.length),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              for (final credit in credits.take(5))
                _CreditLedgerRow(credit: credit),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static int _dDay(DateTime now, DateTime expiry) {
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(expiry.year, expiry.month, expiry.day);
    final d = to.difference(from).inDays;
    return d < 0 ? 0 : d;
  }
}

class _CreditLedgerRow extends StatelessWidget {
  final MakeupCredit credit;
  const _CreditLedgerRow({required this.credit});

  @override
  Widget build(BuildContext context) {
    final isUsed = credit.isUsed;
    final text = isUsed
        ? AppStrings.makeupCreditUsedLine(formatDateMD(credit.usedAt!))
        : AppStrings.makeupCreditAccruedLine(
            formatDateMD(credit.createdAt),
            credit.reason.label,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: isUsed ? AppColors.inkTertiary : AppColors.ink,
        ),
      ),
    );
  }
}
