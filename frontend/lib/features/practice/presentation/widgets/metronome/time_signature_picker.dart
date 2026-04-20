import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../domain/entities/metronome_settings.dart';

/// Bottom sheet picker for selecting time signature.
class TimeSignaturePicker extends StatelessWidget {
  const TimeSignaturePicker({super.key, required this.current});

  final TimeSignature current;

  /// Show the time signature picker as a bottom sheet.
  static Future<TimeSignature?> show(
    BuildContext context,
    TimeSignature current,
  ) {
    return showModalBottomSheet<TimeSignature>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSignaturePicker(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final simpleSignatures =
        TimeSignature.values.where((ts) => ts.isSimple).toList();
    final compoundSignatures =
        TimeSignature.values.where((ts) => ts.isCompound).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const BottomSheetHandle(),
            // Title
            Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Text(
                '박자표 선택',
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Simple time signatures section
            _buildSection(
              context,
              title: '단순 박자',
              description: '일반적인 박자표',
              signatures: simpleSignatures,
            ),
            SizedBox(height: AppSpacing.space4),
            // Compound time signatures section
            _buildSection(
              context,
              title: '복합 박자',
              description: '3박 단위로 나눠지는 박자 (♩. 기준)',
              signatures: compoundSignatures,
            ),
            SizedBox(height: AppSpacing.space6),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<TimeSignature> signatures,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.space1),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: AppSpacing.space3),
          Row(
            children:
                signatures.map((ts) {
                  final isSelected = ts == current;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _TimeSignatureCard(
                        timeSignature: ts,
                        isSelected: isSelected,
                        onTap: () => Navigator.of(context).pop(ts),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TimeSignatureCard extends StatelessWidget {
  const _TimeSignatureCard({
    required this.timeSignature,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSignature timeSignature;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time signature display (stacked numerator/denominator)
            _buildTimeSignatureDisplay(isSelected),
            SizedBox(height: AppSpacing.space2),
            // Main beats info for compound
            if (timeSignature.isCompound) ...[
              Text(
                '큰박 ${timeSignature.mainBeats}개',
                style: AppTypography.captionSmall.copyWith(
                  color:
                      isSelected
                          ? Colors.white70
                          : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSignatureDisplay(bool isSelected) {
    final parts = timeSignature.label.split('/');
    final numerator = parts[0];
    final denominator = parts.length > 1 ? parts[1] : '4';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          numerator,
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            height: 1.0,
          ),
        ),
        Container(
          width: 24,
          height: 2,
          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
        ),
        Text(
          denominator,
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
