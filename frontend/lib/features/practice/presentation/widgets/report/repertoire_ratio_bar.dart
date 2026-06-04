import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/practice_report.dart';

/// Visualises repertoire share of total practice time as horizontal bars.
class RepertoireRatioBar extends StatelessWidget {
  final List<RepertoireRatio> ratios;

  const RepertoireRatioBar({super.key, required this.ratios});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.practiceReportRepertoireRatioTitle,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          if (ratios.isEmpty)
            _EmptyRatio()
          else
            ...ratios.asMap().entries.map((entry) {
              final index = entry.key;
              final ratio = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < ratios.length - 1 ? AppSpacing.space3 : 0,
                ),
                child: _RatioRow(ratio: ratio),
              );
            }),
        ],
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  final RepertoireRatio ratio;

  const _RatioRow({required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ratio.repertoireName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '${ratio.ratioPercent}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: const BoxDecoration(color: AppColors.inkQuaternary),
            ),
            FractionallySizedBox(
              widthFactor: ratio.ratio.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: const BoxDecoration(color: AppColors.paperAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '${ratio.practiceMinutes}${AppStrings.practiceReportMinutesUnit}',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}

class _EmptyRatio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Center(
        child: Text(
          AppStrings.practiceReportEmptyRepertoire,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}
