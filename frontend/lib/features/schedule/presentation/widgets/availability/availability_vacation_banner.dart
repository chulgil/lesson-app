import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/vacation_period.dart';
import '../../providers/vacation_providers.dart';

/// Visualizes registered vacation spans inside the availability screen (#431 §4).
///
/// Calendar-grid cell shading is owned by the booking grid; this banner provides
/// a lightweight, low-risk indication that the teacher has active vacation
/// windows where no student booking will be placed.
class AvailabilityVacationBanner extends ConsumerWidget {
  const AvailabilityVacationBanner({super.key});

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
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space4),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.scheduleMutedBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.scheduleMutedAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.vacationBannerTitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                AppStrings.vacationBannerHint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              for (final period in active)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _VacationRow(period: period),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _VacationRow extends StatelessWidget {
  final VacationPeriod period;
  const _VacationRow({required this.period});

  @override
  Widget build(BuildContext context) {
    final range = AppStrings.vacationCardDateRange(
      _formatShortDate(period.startDate),
      _formatShortDate(period.endDate),
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            range,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
        ),
        if (period.reason != null && period.reason!.isNotEmpty)
          Text(
            period.reason!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  static String _formatShortDate(DateTime d) => '${d.month}/${d.day}';
}
