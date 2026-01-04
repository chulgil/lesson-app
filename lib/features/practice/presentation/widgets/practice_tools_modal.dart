import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/metronome_settings.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../providers/tuner_provider.dart';
import 'metronome/cat_beat_indicator.dart';
import 'tuner/circular_tuner_indicator.dart';
import 'tuner/tuner_cat_indicator.dart';
import 'tuner/tuner_settings_sheet.dart';

/// Practice tools modal with tab-based navigation between Metronome and Tuner.
class PracticeToolsModal extends ConsumerStatefulWidget {
  const PracticeToolsModal({super.key, this.initialTab = 0});

  /// Initial tab index (0 = Metronome, 1 = Tuner)
  final int initialTab;

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PracticeToolsModal(initialTab: initialTab),
    );
  }

  @override
  ConsumerState<PracticeToolsModal> createState() => _PracticeToolsModalState();
}

class _PracticeToolsModalState extends ConsumerState<PracticeToolsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Pre-warm metronome engine
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: AppSpacing.space2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with tabs
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: '메트로놈'),
                      Tab(text: '튜너'),
                    ],
                  ),
                ),
                // Settings button for tuner
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return _tabController.index == 1
                        ? IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => TunerSettingsSheet.show(context),
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            padding: EdgeInsets.zero,
                          )
                        : const SizedBox(width: 40);
                  },
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _MetronomePanel(),
                _TunerPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metronome panel content.
class _MetronomePanel extends ConsumerWidget {
  const _MetronomePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          // Cat beat indicator
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
          Column(
            children: [
              Text(
                '${state.settings.bpm}',
                style: AppTypography.displayLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'BPM',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space4),

          // BPM controls
          Row(
            children: [
              _CircleButton(
                label: '-5',
                onPressed: () =>
                    ref.read(metronomeProvider.notifier).incrementBpm(-5),
              ),
              SizedBox(width: AppSpacing.space2),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.primaryLight,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: state.settings.bpm.toDouble(),
                    min: MetronomeSettings.minBpm.toDouble(),
                    max: MetronomeSettings.maxBpm.toDouble(),
                    onChanged: (value) =>
                        ref.read(metronomeProvider.notifier).setBpm(value.round()),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.space2),
              _CircleButton(
                label: '+5',
                onPressed: () =>
                    ref.read(metronomeProvider.notifier).incrementBpm(5),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.space8),

          // Play/Pause button
          SizedBox(
            width: 80,
            height: 80,
            child: OutlinedButton(
              onPressed: () => ref.read(metronomeProvider.notifier).toggle(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 3),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: state.isPlaying && state.currentBeat > 0
                  ? Text(
                      '${state.currentBeat}',
                      style: AppTypography.displayLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 36,
                      ),
                    )
                  : Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: AppColors.primary,
                    ),
            ),
          ),
          SizedBox(height: AppSpacing.space8),

          // Time signature selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '박자표',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space2),
              Row(
                children: TimeSignature.values.map((ts) {
                  final isSelected = ts == state.settings.timeSignature;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(ts.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            ref.read(metronomeProvider.notifier).setTimeSignature(ts),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.label,
    required this.onPressed,
  });

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
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primary,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: AppTypography.buttonSmall.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Tuner panel content.
class _TunerPanel extends ConsumerStatefulWidget {
  const _TunerPanel();

  @override
  ConsumerState<_TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends ConsumerState<_TunerPanel> {
  @override
  void initState() {
    super.initState();
    // Auto-start tuner when panel is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tunerProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);

    return Column(
      children: [
        // Main tuner area - responsive to screen size
        Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;

                // Use the smaller dimension with padding
                final availableSize = (availableWidth < availableHeight
                    ? availableWidth
                    : availableHeight) - 32; // 16px padding each side

                // Circle size fills available space (indicators are inside)
                final circleSize = availableSize * 1.1; // 110% for circle (bigger for font 72)
                final catSize = circleSize * 0.40; // Cat is 40% of circle (smaller)

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circle with cat (no note inside, speech bubble next to cat)
                    CircularTunerIndicator(
                      size: circleSize,
                      centerChild: TunerCatIndicator(
                        size: catSize,
                        showNote: false, // Don't show note inside cat
                        showSpeechBubble: true, // Show speech bubble next to cat
                      ),
                    ),
                    // Current note display (overlaid below cat face)
                    Positioned(
                      bottom: circleSize * 0.05, // Lower position for note display
                      child: _CurrentNoteDisplay(scale: circleSize / 280), // Scale based on circle size
                    ),
                  ],
                );
              },
            ),
        ),

        SizedBox(height: AppSpacing.space4),

        // Info bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.space6),
          child: const TunerInfoBar(),
        ),
        SizedBox(height: AppSpacing.space4),

        // Start/Stop button
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.space6),
          child: _TunerButton(
            isListening: tunerState.isListening,
            onPressed: () => ref.read(tunerProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }
}

class _TunerButton extends StatelessWidget {
  const _TunerButton({
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? AppColors.error : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isListening ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Current note display widget (fixed position outside circle).
class _CurrentNoteDisplay extends ConsumerWidget {
  const _CurrentNoteDisplay({this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final isPerfect = tunerState.isPerfect;

    // Base font sizes (will be scaled)
    final noteFontSize = 72 * scale;
    final octaveFontSize = 42 * scale;

    if (currentNote == null) {
      // No note detected - show placeholder dash
      return Text(
        '—',
        style: TextStyle(
          fontSize: noteFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
      );
    }

    final noteColor = isPerfect ? Colors.green : AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Note name
        Text(
          currentNote.name.sharpName,
          style: TextStyle(
            fontSize: noteFontSize,
            fontWeight: FontWeight.bold,
            color: noteColor,
          ),
        ),
        // Octave
        Text(
          '${currentNote.octave}',
          style: TextStyle(
            fontSize: octaveFontSize,
            fontWeight: FontWeight.w600,
            color: noteColor.withValues(alpha: 0.7),
          ),
        ),
        // Cent display removed - shown in TunerInfoBar below
      ],
    );
  }
}
