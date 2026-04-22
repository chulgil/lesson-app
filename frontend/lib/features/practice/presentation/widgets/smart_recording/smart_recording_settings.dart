import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/smart_recording.dart';
import '../../../../../features/practice/presentation/providers/smart_recording_provider.dart';

/// Settings widget for smart recording feature.
class SmartRecordingSettingsCard extends ConsumerWidget {
  const SmartRecordingSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(smartRecordingSettingsNotifierProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high,
                    color: AppColors.paperAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트 녹음',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '녹음 앞뒤 무음 구간 자동 제거',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.smartRecordingEnabled,
                  onChanged: (_) {
                    ref
                        .read(smartRecordingSettingsNotifierProvider.notifier)
                        .toggleEnabled();
                  },
                  activeThumbColor: AppColors.paperAccent,
                ),
              ],
            ),

            // Threshold slider (only when enabled)
            if (settings.smartRecordingEnabled) ...[
              const SizedBox(height: AppSpacing.space4),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),

              Row(
                children: [
                  const Icon(
                    Icons.tune,
                    size: 18,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '트림 민감도',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '${(settings.trimThreshold * 100).toInt()}%',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              Row(
                children: [
                  Text(
                    '낮음',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.paperAccent,
                        inactiveTrackColor: AppColors.paperAccent.withValues(
                          alpha: 0.2,
                        ),
                        thumbColor: AppColors.paperAccent,
                        overlayColor: AppColors.paperAccent.withValues(alpha: 0.1),
                      ),
                      child: Slider(
                        value: settings.trimThreshold,
                        min: SmartRecordingState.minThreshold,
                        max: SmartRecordingState.maxThreshold,
                        divisions: 8,
                        onChanged: (value) {
                          ref
                              .read(
                                smartRecordingSettingsNotifierProvider.notifier,
                              )
                              .setThreshold(value);
                        },
                      ),
                    ),
                  ),
                  Text(
                    '높음',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.inkSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '높은 민감도: 작은 소리도 녹음에 포함\n낮은 민감도: 큰 소리만 녹음에 포함',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Middle silence skip section
              const SizedBox(height: AppSpacing.space4),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),

              // Middle silence toggle
              Row(
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 18,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '중간 무음 스킵',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '재생 시 긴 무음 구간 자동 건너뛰기',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.middleSilenceSkipEnabled,
                    onChanged: (_) {
                      ref
                          .read(smartRecordingSettingsNotifierProvider.notifier)
                          .toggleMiddleSilenceSkip();
                    },
                    activeThumbColor: AppColors.paperAccent,
                  ),
                ],
              ),

              // Middle silence threshold slider (only when enabled)
              if (settings.middleSilenceSkipEnabled) ...[
                const SizedBox(height: AppSpacing.space3),
                Row(
                  children: [
                    Text(
                      '무음 감지 기준',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: Text(
                        '${settings.middleSilenceThreshold}초 이상',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Text(
                      '5초',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.paperAccent,
                          inactiveTrackColor: AppColors.paperAccent.withValues(
                            alpha: 0.2,
                          ),
                          thumbColor: AppColors.paperAccent,
                          overlayColor: AppColors.paperAccent.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: Slider(
                          value: settings.middleSilenceThreshold.toDouble(),
                          min: 5,
                          max: 30,
                          divisions: 5,
                          onChanged: (value) {
                            ref
                                .read(
                                  smartRecordingSettingsNotifierProvider
                                      .notifier,
                                )
                                .setMiddleSilenceThreshold(value.toInt());
                          },
                        ),
                      ),
                    ),
                    Text(
                      '30초',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact toggle for smart recording (for use in recording screens).
class SmartRecordingToggle extends ConsumerWidget {
  const SmartRecordingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(smartRecordingSettingsNotifierProvider);

    return InkWell(
      onTap: () {
        ref
            .read(smartRecordingSettingsNotifierProvider.notifier)
            .toggleEnabled();
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color:
              settings.smartRecordingEnabled
                  ? AppColors.paperAccent.withValues(alpha: 0.1)
                  : AppColors.paperDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color:
                settings.smartRecordingEnabled
                    ? AppColors.paperAccent.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: 16,
              color:
                  settings.smartRecordingEnabled
                      ? AppColors.paperAccent
                      : AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '스마트',
              style: AppTypography.caption.copyWith(
                color:
                    settings.smartRecordingEnabled
                        ? AppColors.paperAccent
                        : AppColors.inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
