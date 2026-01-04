import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';

/// Bottom sheet for tuner settings.
class TunerSettingsSheet extends ConsumerWidget {
  const TunerSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TunerSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final settings = tunerState.settings;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '튜너 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1),

            // Settings list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reference frequency
                    _ReferenceFrequencySection(
                      currentFrequency: settings.referenceFrequency,
                      onChanged: (freq) {
                        ref.read(tunerProvider.notifier).setReferenceFrequency(freq);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Transposition
                    _TranspositionSection(
                      currentTransposition: settings.transposition,
                      onChanged: (trans) {
                        ref.read(tunerProvider.notifier).setTransposition(trans);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Difficulty
                    _DifficultySection(
                      currentDifficulty: settings.difficulty,
                      onChanged: (diff) {
                        ref.read(tunerProvider.notifier).setDifficulty(diff);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Enharmonic mode
                    _EnharmonicSection(
                      currentMode: settings.enharmonicMode,
                      onChanged: (mode) {
                        ref.read(tunerProvider.notifier).setEnharmonicMode(mode);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Toggles
                    _ToggleSection(
                      showCombo: settings.showCombo,
                      vibrationFeedback: settings.vibrationFeedback,
                      onShowComboChanged: () {
                        ref.read(tunerProvider.notifier).toggleShowCombo();
                      },
                      onVibrationChanged: () {
                        ref.read(tunerProvider.notifier).toggleVibrationFeedback();
                      },
                    ),

                    const SizedBox(height: 16),
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
        const Text(
          '기준 주파수 (A4)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '오케스트라나 앙상블에 맞춰 조절하세요',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        // Preset buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TunerSettings.frequencyPresets.map((freq) {
            final isSelected = (currentFrequency - freq).abs() < 0.1;
            return ChoiceChip(
              label: Text('${freq.toInt()}Hz'),
              selected: isSelected,
              onSelected: (_) => onChanged(freq),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Slider for fine tuning
        Row(
          children: [
            Text(
              '${TunerSettings.minReferenceFrequency.toInt()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Expanded(
              child: Slider(
                value: currentFrequency,
                min: TunerSettings.minReferenceFrequency,
                max: TunerSettings.maxReferenceFrequency,
                divisions: 200, // 0.1Hz steps
                label: '${currentFrequency.toStringAsFixed(1)}Hz',
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ),
            Text(
              '${TunerSettings.maxReferenceFrequency.toInt()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),

        Center(
          child: Text(
            'A4 = ${currentFrequency.toStringAsFixed(1)}Hz',
            style: const TextStyle(
              fontSize: 14,
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
        const Text(
          '조옮김 (관악기용)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '악보 기준 음을 실음으로 변환합니다',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Transposition.values.map((trans) {
            final isSelected = currentTransposition == trans;
            return ChoiceChip(
              label: Text(trans.label),
              selected: isSelected,
              onSelected: (_) => onChanged(trans),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        if (currentTransposition != Transposition.c)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${currentTransposition.description} 악기용',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
        const Text(
          '판정 난이도',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Perfect/Good 판정 기준을 조절합니다',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: TunerDifficulty.values.map((diff) {
            final isSelected = currentDifficulty == diff;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(diff.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(diff),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Perfect: ±${currentDifficulty.perfectCent}¢ / Good: ±${currentDifficulty.goodCent}¢',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
        const Text(
          '이명동음 표시',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '반음 표기 방식을 선택합니다',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EnharmonicMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return ChoiceChip(
              label: Text('${mode.label} (${mode.example})'),
              selected: isSelected,
              onSelected: (_) => onChanged(mode),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            );
          }).toList(),
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
          title: const Text('콤보 카운터 표시'),
          subtitle: const Text('Perfect 연속 달성 시 콤보 표시'),
          value: showCombo,
          onChanged: (_) => onShowComboChanged(),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('진동 피드백'),
          subtitle: const Text('Perfect 튜닝 시 진동'),
          value: vibrationFeedback,
          onChanged: (_) => onVibrationChanged(),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
