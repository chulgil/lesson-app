import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';

/// Bottom sheet for tuner settings.
class TunerSettingsSheet extends ConsumerWidget {
  const TunerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TunerSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final settings = tunerState.settings;

    return Container(
      // Limit height to 60% of screen so it doesn't go too high
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const BottomSheetHandle(),

            // Title
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
              // 패턴. Playfair appBarTitle 로 통일 (이미 w700).
              child: Text(
                AppStrings.tunerSettingsTitle,
                style: NotebookTypography.appBarTitle,
              ),
            ),

            const Divider(height: 1),

            // Settings list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference frequency
                    _ReferenceFrequencySection(
                      currentFrequency: settings.referenceFrequency,
                      onChanged: (freq) {
                        ref
                            .read(tunerProvider.notifier)
                            .setReferenceFrequency(freq);
                      },
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Transposition
                    _TranspositionSection(
                      currentTransposition: settings.transposition,
                      onChanged: (trans) {
                        ref
                            .read(tunerProvider.notifier)
                            .setTransposition(trans);
                      },
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Difficulty
                    _DifficultySection(
                      currentDifficulty: settings.difficulty,
                      onChanged: (diff) {
                        ref.read(tunerProvider.notifier).setDifficulty(diff);
                      },
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Clef type
                    _ClefSection(
                      currentClef: settings.clefType,
                      autoSwitchClef: settings.autoSwitchClef,
                      onChanged: (clef) {
                        ref.read(tunerProvider.notifier).setClefType(clef);
                      },
                      onAutoSwitchChanged: () {
                        ref.read(tunerProvider.notifier).toggleAutoSwitchClef();
                      },
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Enharmonic mode
                    _EnharmonicSection(
                      currentMode: settings.enharmonicMode,
                      onChanged: (mode) {
                        ref
                            .read(tunerProvider.notifier)
                            .setEnharmonicMode(mode);
                      },
                    ),

                    const SizedBox(height: AppSpacing.space6),

                    // Toggles
                    _ToggleSection(
                      showCombo: settings.showCombo,
                      vibrationFeedback: settings.vibrationFeedback,
                      onShowComboChanged: () {
                        ref.read(tunerProvider.notifier).toggleShowCombo();
                      },
                      onVibrationChanged: () {
                        ref
                            .read(tunerProvider.notifier)
                            .toggleVibrationFeedback();
                      },
                    ),

                    const SizedBox(height: AppSpacing.space4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reference frequency selection section.
class _ReferenceFrequencySection extends StatelessWidget {
  const _ReferenceFrequencySection({
    required this.currentFrequency,
    required this.onChanged,
  });

  final double currentFrequency;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 튜너 설정 섹션 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(
          AppStrings.tunerReferenceFrequencyTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '오케스트라나 앙상블에 맞춰 조절하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Preset buttons
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              TunerSettings.frequencyPresets.map((freq) {
                final isSelected = (currentFrequency - freq).abs() < 0.1;
                return ChoiceChip(
                  label: Text('${freq.toInt()}Hz'),
                  selected: isSelected,
                  onSelected: (_) => onChanged(freq),
                  selectedColor: AppColors.paperAccentSoft,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Slider for fine tuning
        Row(
          children: [
            Text(
              '${TunerSettings.minReferenceFrequency.toInt()}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            Expanded(
              child: Slider(
                value: currentFrequency,
                min: TunerSettings.minReferenceFrequency,
                max: TunerSettings.maxReferenceFrequency,
                divisions: 200, // 0.1Hz steps
                label: '${currentFrequency.toStringAsFixed(1)}Hz',
                activeColor: AppColors.paperAccent,
                onChanged: onChanged,
              ),
            ),
            Text(
              '${TunerSettings.maxReferenceFrequency.toInt()}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),

        Center(
          child: Text(
            'A4 = ${currentFrequency.toStringAsFixed(1)}Hz',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Transposition selection section.
class _TranspositionSection extends StatelessWidget {
  const _TranspositionSection({
    required this.currentTransposition,
    required this.onChanged,
  });

  final Transposition currentTransposition;
  final ValueChanged<Transposition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 튜너 설정 섹션 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(
          AppStrings.tunerTransposeTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '악보 기준 음을 실음으로 변환합니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              Transposition.values.map((trans) {
                final isSelected = currentTransposition == trans;
                return ChoiceChip(
                  label: Text(trans.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(trans),
                  selectedColor: AppColors.paperAccentSoft,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),

        if (currentTransposition != Transposition.c)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Text(
              '${currentTransposition.description} 악기용',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Difficulty selection section.
class _DifficultySection extends StatelessWidget {
  const _DifficultySection({
    required this.currentDifficulty,
    required this.onChanged,
  });

  final TunerDifficulty currentDifficulty;
  final ValueChanged<TunerDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 튜너 설정 섹션 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(
          AppStrings.tunerDifficultyTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          'Perfect/Good 판정 기준을 조절합니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        Row(
          children:
              TunerDifficulty.values.map((diff) {
                final isSelected = currentDifficulty == diff;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                    ),
                    child: ChoiceChip(
                      label: Text(diff.label),
                      selected: isSelected,
                      onSelected: (_) => onChanged(diff),
                      selectedColor: AppColors.paperAccentSoft,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Text(
            'Perfect: ±${currentDifficulty.perfectCent}¢ / Good: ±${currentDifficulty.goodCent}¢',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Enharmonic display mode section.
class _EnharmonicSection extends StatelessWidget {
  const _EnharmonicSection({
    required this.currentMode,
    required this.onChanged,
  });

  final EnharmonicMode currentMode;
  final ValueChanged<EnharmonicMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 튜너 설정 섹션 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(
          AppStrings.tunerEnharmonicTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '반음 표기 방식을 선택합니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              EnharmonicMode.values.map((mode) {
                final isSelected = currentMode == mode;
                return ChoiceChip(
                  label: Text('${mode.label} (${mode.example})'),
                  selected: isSelected,
                  onSelected: (_) => onChanged(mode),
                  selectedColor: AppColors.paperAccentSoft,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// Clef type selection section.
class _ClefSection extends StatelessWidget {
  const _ClefSection({
    required this.currentClef,
    required this.autoSwitchClef,
    required this.onChanged,
    required this.onAutoSwitchChanged,
  });

  final ClefType currentClef;
  final bool autoSwitchClef;
  final ValueChanged<ClefType> onChanged;
  final VoidCallback onAutoSwitchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 튜너 설정 섹션 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(AppStrings.tunerClefTitle, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space1),
        Text(
          '오선지 표기 방식을 선택합니다',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        Row(
          children:
              ClefType.values.map((clef) {
                final isSelected = currentClef == clef;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space1,
                    ),
                    child: ChoiceChip(
                      label: Text('${clef.symbol} ${clef.label}'),
                      selected: isSelected,
                      onSelected: (_) => onChanged(clef),
                      selectedColor: AppColors.paperAccentSoft,
                      labelStyle: TextStyle(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Auto-switch toggle
        InkWell(
          onTap: onAutoSwitchChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                Checkbox(
                  value: autoSwitchClef,
                  onChanged: (_) => onAutoSwitchChanged(),
                  activeColor: AppColors.paperAccent,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '자동 전환',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '음역대에 따라 음자리표 자동 전환 (첼로 등)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Toggle switches section.
class _ToggleSection extends StatelessWidget {
  const _ToggleSection({
    required this.showCombo,
    required this.vibrationFeedback,
    required this.onShowComboChanged,
    required this.onVibrationChanged,
  });

  final bool showCombo;
  final bool vibrationFeedback;
  final VoidCallback onShowComboChanged;
  final VoidCallback onVibrationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text(AppStrings.tunerShowComboTitle),
          subtitle: const Text('Perfect 연속 달성 시 콤보 표시'),
          value: showCombo,
          onChanged: (_) => onShowComboChanged(),
          activeThumbColor: AppColors.paperAccent,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text(AppStrings.tunerVibrationFeedbackTitle),
          subtitle: const Text('Perfect 튜닝 시 진동'),
          value: vibrationFeedback,
          onChanged: (_) => onVibrationChanged(),
          activeThumbColor: AppColors.paperAccent,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
