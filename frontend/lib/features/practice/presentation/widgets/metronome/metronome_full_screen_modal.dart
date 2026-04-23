import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../features/practice/domain/entities/metronome_settings.dart';
import '../../../../../features/practice/presentation/providers/metronome_provider.dart';
import 'cat_beat_indicator.dart';

/// Full screen metronome modal with all controls.
///
/// Features:
/// - Large cat beat indicator
/// - BPM slider and ±5 buttons
/// - Time signature selector
/// - Sound selector
/// - Visual/vibration toggles
class MetronomeFullScreenModal extends ConsumerStatefulWidget {
  const MetronomeFullScreenModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MetronomeFullScreenModal(),
    );
  }

  @override
  ConsumerState<MetronomeFullScreenModal> createState() =>
      _MetronomeFullScreenModalState();
}

class _MetronomeFullScreenModalState
    extends ConsumerState<MetronomeFullScreenModal> {
  @override
  void initState() {
    super.initState();
    // Pre-warm engine to reduce first-play latency
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          const BottomSheetHandle(
            margin: EdgeInsets.only(top: AppSpacing.space2),
          ),

          // Header
          _Header(onClose: () => Navigator.pop(context)),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.space6),
              child: Column(
                children: [
                  // Cat beat indicator - large for visibility
                  CatBeatIndicator(
                    currentBeat: state.currentBeat,
                    timeSignature: state.settings.timeSignature,
                    isPlaying: state.isPlaying,
                    accentPattern: state.settings.accentPattern,
                    bpm: state.settings.bpm,
                    size: 140,
                  ),
                  SizedBox(height: AppSpacing.space8),

                  // BPM display
                  _BpmDisplay(bpm: state.settings.bpm),
                  SizedBox(height: AppSpacing.space4),

                  // BPM controls
                  _BpmSlider(
                    bpm: state.settings.bpm,
                    onChanged:
                        (value) =>
                            ref.read(metronomeProvider.notifier).setBpm(value),
                    onDecrement:
                        () => ref
                            .read(metronomeProvider.notifier)
                            .incrementBpm(-5),
                    onIncrement:
                        () => ref
                            .read(metronomeProvider.notifier)
                            .incrementBpm(5),
                  ),
                  SizedBox(height: AppSpacing.space8),

                  // Play/Pause button with beat number
                  _LargePlayButton(
                    isPlaying: state.isPlaying,
                    currentBeat: state.currentBeat,
                    onPressed:
                        () => ref.read(metronomeProvider.notifier).toggle(),
                  ),
                  SizedBox(height: AppSpacing.space8),

                  // Time signature selector
                  _TimeSignatureSelector(
                    selected: state.settings.timeSignature,
                    onChanged:
                        (ts) => ref
                            .read(metronomeProvider.notifier)
                            .setTimeSignature(ts),
                  ),
                  SizedBox(height: AppSpacing.space6),

                  // Subdivision selector
                  _SubdivisionSelector(
                    selected: state.settings.subdivision,
                    onChanged:
                        (sub) => ref
                            .read(metronomeProvider.notifier)
                            .setSubdivision(sub),
                  ),
                  SizedBox(height: AppSpacing.space6),

                  // Sound selector
                  _SoundSelector(
                    selected: state.settings.sound,
                    onChanged:
                        (sound) => ref
                            .read(metronomeProvider.notifier)
                            .setSound(sound),
                  ),
                  SizedBox(height: AppSpacing.space6),

                  // Accent pattern selector
                  _AccentPatternSelector(
                    selected: state.settings.accentPattern,
                    onChanged:
                        (pattern) => ref
                            .read(metronomeProvider.notifier)
                            .setAccentPattern(pattern),
                  ),
                  SizedBox(height: AppSpacing.space6),

                  // Toggle options
                  _ToggleOptions(
                    visualFlash: state.settings.visualFlash,
                    vibration: state.settings.vibration,
                    onVisualFlashChanged:
                        () =>
                            ref
                                .read(metronomeProvider.notifier)
                                .toggleVisualFlash(),
                    onVibrationChanged:
                        () =>
                            ref
                                .read(metronomeProvider.notifier)
                                .toggleVibration(),
                  ),
                  // Extra bottom padding for safe scrolling
                  SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.space12), // Balance for close button
          Expanded(
            // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
            // 패턴. Playfair appBarTitle 로 통일.
            child: Text(
              '메트로놈',
              style: NotebookTypography.appBarTitle,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      ),
    );
  }
}

class _BpmDisplay extends StatelessWidget {
  const _BpmDisplay({required this.bpm});

  final int bpm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$bpm',
          style: AppTypography.displayLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.paperAccent,
          ),
        ),
        Text(
          'BPM',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _BpmSlider extends StatelessWidget {
  const _BpmSlider({
    required this.bpm,
    required this.onChanged,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int bpm;
  final ValueChanged<int> onChanged;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // -5 button
        _CircleButton(label: '-5', onPressed: onDecrement),
        SizedBox(width: AppSpacing.space2),

        // Slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.paperAccent,
              inactiveTrackColor: AppColors.paperAccentSoft,
              thumbColor: AppColors.paperAccent,
              overlayColor: AppColors.paperAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: bpm.toDouble(),
              min: MetronomeSettings.minBpm.toDouble(),
              max: MetronomeSettings.maxBpm.toDouble(),
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.space2),

        // +5 button
        _CircleButton(label: '+5', onPressed: onIncrement),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paperAccentSoft,
          foregroundColor: AppColors.paperAccent,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: AppTypography.button.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _LargePlayButton extends StatelessWidget {
  const _LargePlayButton({
    required this.isPlaying,
    required this.onPressed,
    required this.currentBeat,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final int currentBeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
          side: BorderSide(color: AppColors.paperAccent, width: 3),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child:
            isPlaying && currentBeat > 0
                ? Text(
                  '$currentBeat',
                  style: AppTypography.displayLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.paperAccent,
                    fontSize: 36,
                  ),
                )
                : Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 48,
                  color: AppColors.paperAccent,
                ),
      ),
    );
  }
}

class _TimeSignatureSelector extends StatelessWidget {
  const _TimeSignatureSelector({
    required this.selected,
    required this.onChanged,
  });

  final TimeSignature selected;
  final ValueChanged<TimeSignature> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '박자표',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space1,
          runSpacing: AppSpacing.space1,
          children:
              TimeSignature.values.map((ts) {
                final isSelected = ts == selected;
                return ChoiceChip(
                  label: Text(ts.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(ts),
                  selectedColor: AppColors.paperAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
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

class _SubdivisionSelector extends StatelessWidget {
  const _SubdivisionSelector({required this.selected, required this.onChanged});

  final Subdivision selected;
  final ValueChanged<Subdivision> onChanged;

  @override
  Widget build(BuildContext context) {
    // Show basic subdivisions (quarter, eighth, triplet, sixteenth) in main row
    // Show advanced subdivisions in expandable section
    final basicSubdivisions =
        Subdivision.values.where((s) => s.isBasic).toList();
    final advancedSubdivisions =
        Subdivision.values.where((s) => !s.isBasic).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '서브디비전',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.space2),
        // Basic subdivisions row
        Row(
          children:
              basicSubdivisions.map((sub) {
                final isSelected = sub == selected;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _SubdivisionChip(
                      subdivision: sub,
                      isSelected: isSelected,
                      onSelected: () => onChanged(sub),
                    ),
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: AppSpacing.space2),
        // Advanced subdivisions (5, 6 연음)
        if (advancedSubdivisions.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children:
                advancedSubdivisions.map((sub) {
                  final isSelected = sub == selected;
                  return ChoiceChip(
                    label: Text(sub.label),
                    selected: isSelected,
                    onSelected: (_) => onChanged(sub),
                    selectedColor: AppColors.paperAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
          ),
          SizedBox(height: AppSpacing.space2),
        ],
        // Visual pattern display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  selected.visualPattern,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(width: AppSpacing.space4),
                Text(
                  '(${selected.englishName})',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
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

class _SubdivisionChip extends StatelessWidget {
  const _SubdivisionChip({
    required this.subdivision,
    required this.isSelected,
    required this.onSelected,
  });

  final Subdivision subdivision;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccent : AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subdivision.visualPattern,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subdivision.label,
              style: AppTypography.caption.copyWith(
                color:
                    isSelected
                        ? AppColors.paper.withValues(alpha: 0.9)
                        : AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundSelector extends StatelessWidget {
  const _SoundSelector({required this.selected, required this.onChanged});

  final MetronomeSound selected;
  final ValueChanged<MetronomeSound> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소리',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              MetronomeSound.values.map((sound) {
                final isSelected = sound == selected;
                return ChoiceChip(
                  label: Text(sound.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(sound),
                  selectedColor: AppColors.paperAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
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

class _AccentPatternSelector extends StatelessWidget {
  const _AccentPatternSelector({
    required this.selected,
    required this.onChanged,
  });

  final AccentPattern selected;
  final ValueChanged<AccentPattern> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '박자 패턴',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children:
              AccentPattern.values.map((pattern) {
                final isSelected = pattern == selected;
                return ChoiceChip(
                  label: Text(pattern.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(pattern),
                  selectedColor: AppColors.paperAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: AppSpacing.space1),
        Text(
          selected.description,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _ToggleOptions extends StatelessWidget {
  const _ToggleOptions({
    required this.visualFlash,
    required this.vibration,
    required this.onVisualFlashChanged,
    required this.onVibrationChanged,
  });

  final bool visualFlash;
  final bool vibration;
  final VoidCallback onVisualFlashChanged;
  final VoidCallback onVibrationChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '옵션',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.space2),
        _ToggleRow(
          label: '시각 플래시',
          value: visualFlash,
          onChanged: onVisualFlashChanged,
        ),
        _ToggleRow(
          label: '진동',
          value: vibration,
          onChanged: onVibrationChanged,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeThumbColor: AppColors.paperAccent,
          ),
        ],
      ),
    );
  }
}
