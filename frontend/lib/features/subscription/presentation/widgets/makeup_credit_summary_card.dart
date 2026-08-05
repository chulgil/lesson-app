import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/makeup_credit.dart';
import '../providers/makeup_credit_providers.dart';

/// 학생 측 보강 크레딧 요약 카드 (#1165 진입점).
///
/// 예약 흐름 밖에서 잔액·만료 임박을 확인할 수 있도록 수강권 목록 하단에 노출한다.
/// 탭하면 [onTap] (전체 내역 = MakeupCreditScreen) 으로 이동한다.
/// 크레딧 이력이 없으면 아무것도 그리지 않는다([MakeupCreditCard] 와 동일 규칙).
class MakeupCreditSummaryCard extends ConsumerWidget {
  /// 카드 탭 콜백 — 보강 크레딧 전체 화면으로 이동.
  final VoidCallback onTap;

  const MakeupCreditSummaryCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(studentMakeupCreditsProvider);
    return creditsAsync.when(
      data: (credits) {
        if (credits.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        final balance = MakeupCreditBalance.fromCredits(credits, now);
        return Material(
          color: AppColors.paperDark,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.redeem_outlined,
                    size: AppSpacing.iconMD,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.makeupCreditTitle,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summaryLine(now, balance),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: AppSpacing.iconSM,
                    color: AppColors.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// "보유: N회 · 가장 빠른 만료: M/D(D-n)" — 만료 정보가 없으면 잔액만.
  String _summaryLine(DateTime now, MakeupCreditBalance balance) {
    final balanceLabel = AppStrings.makeupCreditBalanceLabel(
      balance.availableCount,
    );
    final expiry = balance.earliestExpiry;
    if (expiry == null) return balanceLabel;
    return '$balanceLabel · '
        '${AppStrings.makeupCreditEarliestExpiry(formatDateMD(expiry), _dDay(now, expiry))}';
  }

  static int _dDay(DateTime now, DateTime expiry) {
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(expiry.year, expiry.month, expiry.day);
    final d = to.difference(from).inDays;
    return d < 0 ? 0 : d;
  }
}
