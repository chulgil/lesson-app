import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/metronome_settings.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../domain/entities/tuner_settings.dart';
import '../../domain/entities/tuner_types.dart';
import '../providers/tuner_combo_provider.dart';
import '../providers/tuner_provider.dart';
import 'metronome/cat_beat_indicator.dart';
import 'tuner/circular_tuner_indicator.dart';
import 'tuner/clef_svgs.dart';
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
                  alignment: Alignment.topCenter,
                  children: [
                    // Circle with cat (positioned 0px from top)
                    Positioned(
                      top: 0,
                      child: CircularTunerIndicator(
                        size: circleSize,
                        centerChild: TunerCatIndicator(
                          size: catSize,
                          showNote: false, // Don't show note inside cat
                          showSpeechBubble: true, // Show speech bubble next to cat
                        ),
                      ),
                    ),
                    // Current note display (below circle, moved up more)
                    Positioned(
                      top: circleSize - circleSize * 0.15 - 100,
                      child: _CurrentNoteDisplay(scale: (circleSize / 280) / 1.1), // 1.1x smaller
                    ),
                  ],
                );
              },
            ),
        ),

        SizedBox(height: AppSpacing.space4),

        // Bottom controls: Info bar (left) - Button (center) - Staff (right)
        // Stack layout: side widgets behind button's glow effect
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space4,
            right: AppSpacing.space4,
            bottom: AppSpacing.space6,
          ),
          child: SizedBox(
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Background layer: Staff (left) + Info bar (right) - hide when yellow curtain fully covers
                if (!ref.watch(isCurtainFullyCoveredProvider))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: staff (up 80px, inward 30px from edge)
                      Transform.translate(
                        offset: const Offset(10, -80),
                        child: const _TunerStaff(width: 106, height: 80),
                      ),
                      // Right side: info bar (up 80px, inward 30px from edge)
                      Transform.translate(
                        offset: const Offset(-10, -80),
                        child: const TunerInfoBar(),
                      ),
                    ],
                  ),
                // Foreground layer: Button (center) - rendered last (on top, covers side widgets)
                _TunerButton(
                  isListening: tunerState.isListening,
                  onPressed: () => ref.read(tunerProvider.notifier).toggle(),
                ),
              ],
            ),
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

    // Apply 1.1x size reduction and scale
    final adjustedScale = scale / 1.1;

    // Base font sizes (will be scaled)
    final noteFontSize = 72 * adjustedScale;
    final octaveFontSize = 42 * adjustedScale;

    if (currentNote == null) {
      // No note detected - show nothing (removed arrows)
      return const SizedBox.shrink();
    }

    // Green when perfect, primary color otherwise (80% opacity)
    final noteColor = isPerfect
        ? Colors.green.withValues(alpha: 0.9)
        : AppColors.primary.withValues(alpha: 0.8);

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

/// Musical staff with note display for tuner.
/// Shows the current note on a 5-line staff when pitch is within beginner threshold.
/// Uses SVG for accurate clef rendering.
class _TunerStaff extends ConsumerWidget {
  const _TunerStaff({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final clefType = tunerState.settings.clefType;
    final autoSwitchClef = tunerState.settings.autoSwitchClef;

    // Use beginner-level threshold (±20 cents) for staff display
    final isWithinBeginnerThreshold = currentNote != null &&
        currentNote.centDeviation.abs() <= TunerDifficulty.beginner.perfectCent;

    final displayNote = isWithinBeginnerThreshold ? currentNote : null;

    // Determine effective clef (auto-switch only if enabled in settings)
    final effectiveClef = displayNote != null
        ? _getEffectiveClef(displayNote, clefType, autoSwitchClef)
        : clefType;

    // Get SVG for the clef
    final clefSvg = switch (effectiveClef) {
      ClefType.treble => trebleClefSvg,
      ClefType.bass => bassClefSvg,
      ClefType.alto => altoClefSvg,
    };

    // Calculate proportions
    final lineSpacing = height / 6;

    // Clef-specific height (treble clef needs to be 1.5x bigger)
    final clefHeight = switch (effectiveClef) {
      ClefType.treble => height * 0.85 * 1.5,
      ClefType.bass => height * 0.85,
      ClefType.alto => height * 0.85,
    };

    // Clef-specific left offset (treble clef needs to be more to the left)
    final clefLeftOffset = switch (effectiveClef) {
      ClefType.treble => -20.0,
      ClefType.bass => 2.0,
      ClefType.alto => 2.0,
    };

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1: Staff lines
          CustomPaint(
            size: Size(width, height),
            painter: _StaffLinesPainter(),
          ),

          // Layer 2: Clef SVG (only set height, let width auto-calculate to preserve aspect ratio)
          Positioned(
            left: clefLeftOffset,
            top: (height - clefHeight) / 2,
            child: SvgPicture.string(
              clefSvg,
              height: clefHeight,
              colorFilter: ColorFilter.mode(
                Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),
          ),

          // Layer 3: Note
          if (displayNote != null)
            CustomPaint(
              size: Size(width, height),
              painter: _NotePainter(
                note: displayNote,
                effectiveClef: effectiveClef,
                lineSpacing: lineSpacing,
              ),
            ),
        ],
      ),
    );
  }

  /// Get effective clef for displaying a note.
  /// If autoSwitchClef is enabled, switches based on note range (for cello, etc.)
  /// Otherwise, always uses the user's preferred clef setting.
  ClefType _getEffectiveClef(TunerNote note, ClefType preferredClef, bool autoSwitch) {
    // If auto-switch is disabled, always use preferred clef
    if (!autoSwitch) {
      return preferredClef;
    }

    // Auto-switch mode: check if note is in preferred clef range first
    final naturalName = note.name.sharpName.replaceAll('#', '');
    final noteKey = '$naturalName${note.octave}';

    final preferredPositions = _getPositionsForClef(preferredClef);
    if (preferredPositions.containsKey(noteKey)) {
      return preferredClef;
    }

    // Try other clefs if note is outside preferred clef range
    for (final clef in ClefType.values) {
      if (clef == preferredClef) continue;
      final positions = _getPositionsForClef(clef);
      if (positions.containsKey(noteKey)) {
        return clef;
      }
    }

    return preferredClef; // Fallback
  }

  static Map<String, double> _getPositionsForClef(ClefType clef) {
    switch (clef) {
      case ClefType.treble:
        return {
          'C3': 9.5, 'D3': 9.0, 'E3': 8.5, 'F3': 8.0, 'G3': 7.5, 'A3': 7.0, 'B3': 6.5,
          'C4': 6.0, 'D4': 5.5, 'E4': 5.0, 'F4': 4.5, 'G4': 4.0, 'A4': 3.5, 'B4': 3.0,
          'C5': 2.5, 'D5': 2.0, 'E5': 1.5, 'F5': 1.0, 'G5': 0.5, 'A5': 0.0, 'B5': -0.5,
          'C6': -1.0, 'D6': -1.5, 'E6': -2.0, 'F6': -2.5, 'G6': -3.0, 'A6': -3.5, 'B6': -4.0,
        };
      case ClefType.bass:
        // Bass clef: G2 on line 1 (bottom=5.0), D3 on line 3 (middle=3.0), A3 on line 5 (top=1.0)
        return {
          'E1': 9.5, 'F1': 9.0, 'G1': 8.5, 'A1': 8.0, 'B1': 7.5,
          'C2': 7.0, 'D2': 6.5, 'E2': 6.0, 'F2': 5.5, 'G2': 5.0, 'A2': 4.5, 'B2': 4.0,
          'C3': 3.5, 'D3': 3.0, 'E3': 2.5, 'F3': 2.0, 'G3': 1.5, 'A3': 1.0, 'B3': 0.5,
          'C4': 0.0, 'D4': -0.5, 'E4': -1.0, 'F4': -1.5, 'G4': -2.0, 'A4': -2.5, 'B4': -3.0,
        };
      case ClefType.alto:
        // Alto clef: F3 on line 1 (bottom), C4 on line 3 (middle), G4 on line 5 (top)
        return {
          'C2': 10.0, 'D2': 9.5, 'E2': 9.0, 'F2': 8.5, 'G2': 8.0, 'A2': 7.5, 'B2': 7.0,
          'C3': 6.5, 'D3': 6.0, 'E3': 5.5, 'F3': 5.0, 'G3': 4.5, 'A3': 4.0, 'B3': 3.5,
          'C4': 3.0, 'D4': 2.5, 'E4': 2.0, 'F4': 1.5, 'G4': 1.0, 'A4': 0.5, 'B4': 0.0,
          'C5': -0.5, 'D5': -1.0, 'E5': -1.5, 'F5': -2.0, 'G5': -2.5, 'A5': -3.0, 'B5': -3.5,
        };
    }
  }
}

/// Painter for staff lines only.
class _StaffLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final lineSpacing = size.height / 6;
    final startX = 0.0;
    final endX = size.width;

    for (var i = 1; i <= 5; i++) {
      final y = i * lineSpacing;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for note only.
class _NotePainter extends CustomPainter {
  _NotePainter({
    required this.note,
    required this.effectiveClef,
    required this.lineSpacing,
  });

  final TunerNote note;
  final ClefType effectiveClef;
  final double lineSpacing;

  /// Calculate position for any note, even if outside predefined range.
  double _getPositionForNote(String naturalName, int octave) {
    final positions = _TunerStaff._getPositionsForClef(effectiveClef);
    final noteKey = '$naturalName$octave';

    // If note is in predefined range, use it directly
    if (positions.containsKey(noteKey)) {
      return positions[noteKey]!;
    }

    // Find a reference note in the same pitch class but different octave
    for (int refOctave = 1; refOctave <= 7; refOctave++) {
      final refKey = '$naturalName$refOctave';
      if (positions.containsKey(refKey)) {
        final refPosition = positions[refKey]!;
        // Each octave is 7 diatonic steps = 3.5 position units
        final octaveDiff = octave - refOctave;
        return refPosition - (octaveDiff * 3.5);
      }
    }

    return 3.0; // Fallback to middle line
  }

  @override
  void paint(Canvas canvas, Size size) {
    final naturalName = note.name.sharpName.replaceAll('#', '');
    final position = _getPositionForNote(naturalName, note.octave);

    final y = position * lineSpacing;
    final x = size.width * 0.7; // Note in right portion
    final noteRadius = lineSpacing * 0.55;

    // Draw note head
    final notePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteRadius * 2.2,
        height: noteRadius * 1.6,
      ),
      notePaint,
    );
    canvas.restore();

    // Draw stem
    final stemPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemUp = position >= 3.0;
    final stemLength = lineSpacing * 3.5;

    if (stemUp) {
      final stemX = x + noteRadius * 0.9;
      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, y - stemLength),
        stemPaint,
      );
    } else {
      final stemX = x - noteRadius * 0.9;
      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, y + stemLength),
        stemPaint,
      );
    }

    // Draw ledger lines if needed
    final ledgerPaint = Paint()
      ..color = Colors.grey[500]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ledgerWidth = noteRadius * 2.5;

    if (position > 5) {
      for (var i = 6.0; i <= position; i += 1.0) {
        final ledgerY = i * lineSpacing;
        canvas.drawLine(
          Offset(x - ledgerWidth, ledgerY),
          Offset(x + ledgerWidth, ledgerY),
          ledgerPaint,
        );
      }
    }

    if (position < 1) {
      for (var i = 0.0; i >= position; i -= 1.0) {
        final ledgerY = i * lineSpacing;
        canvas.drawLine(
          Offset(x - ledgerWidth, ledgerY),
          Offset(x + ledgerWidth, ledgerY),
          ledgerPaint,
        );
      }
    }

    // Draw sharp symbol if accidental
    if (note.name.isAccidental) {
      final accidentalPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final accidentalX = x - noteRadius * 2.5;
      final accidentalSize = lineSpacing * 0.5;

      // Sharp symbol (#)
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.3, y - accidentalSize),
        Offset(accidentalX - accidentalSize * 0.3, y + accidentalSize),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX + accidentalSize * 0.3, y - accidentalSize),
        Offset(accidentalX + accidentalSize * 0.3, y + accidentalSize),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.6, y - accidentalSize * 0.3),
        Offset(accidentalX + accidentalSize * 0.6, y - accidentalSize * 0.5),
        accidentalPaint,
      );
      canvas.drawLine(
        Offset(accidentalX - accidentalSize * 0.6, y + accidentalSize * 0.3),
        Offset(accidentalX + accidentalSize * 0.6, y + accidentalSize * 0.1),
        accidentalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotePainter oldDelegate) {
    return oldDelegate.note != note || oldDelegate.effectiveClef != effectiveClef;
  }
}
