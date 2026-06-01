import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../providers/tuner_provider.dart';
import '../tuner/circular_tuner_indicator.dart';
import '../tuner/tuner_cat_indicator.dart';
import 'tuner_staff.dart';

/// Tuner panel content.
class TunerPanel extends ConsumerStatefulWidget {
  const TunerPanel({super.key});

  @override
  ConsumerState<TunerPanel> createState() => _TunerPanelState();
}

class _TunerPanelState extends ConsumerState<TunerPanel> {
  // Note: Tuner start/stop is now managed by PracticeToolsModal
  // to properly handle tab changes and app lifecycle

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main tuner area - responsive to screen size
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              // Use the smaller dimension with padding
              final availableSize =
                  (availableWidth < availableHeight
                      ? availableWidth
                      : availableHeight) -
                  32; // 16px padding each side

              // Circle size fills available space (indicators are inside)
              final circleSize =
                  availableSize * 1.1; // 110% for circle (bigger for font 72)
              final catSize =
                  circleSize * 0.40; // Cat is 40% of circle (smaller)

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
                        showSpeechBubble:
                            true, // Show speech bubble next to cat
                      ),
                    ),
                  ),
                  // Current note display (below circle, moved up more)
                  Positioned(
                    top: circleSize - circleSize * 0.15 - 100,
                    child: CurrentNoteDisplay(
                      scale: (circleSize / 280) / 1.1,
                    ), // 1.1x smaller
                  ),
                ],
              );
            },
          ),
        ),

        SizedBox(height: AppSpacing.space4),

        // Bottom controls: Staff (left) + Info bar (right) - 1.5x bigger, at bottom
        Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space4,
            right: AppSpacing.space4,
            bottom: AppSpacing.space6,
          ),
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Staff display (1.24x size)
                const TunerStaff(width: 132, height: 99),
                // Info bar (1.24x size)
                Transform.scale(scale: 1.24, child: const TunerInfoBar()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Current note display widget (fixed position outside circle).
class CurrentNoteDisplay extends ConsumerWidget {
  const CurrentNoteDisplay({super.key, this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final displayNote = ref.watch(currentDisplayNoteProvider);
    final isPerfect = tunerState.isPerfect;

    // Apply 1.1x size reduction and scale
    final adjustedScale = scale / 1.1;

    // Base font sizes (will be scaled)
    final noteFontSize = 72 * adjustedScale;
    final octaveFontSize = 42 * adjustedScale;

    if (displayNote == null) {
      // No note detected - show nothing (removed arrows)
      return const SizedBox.shrink();
    }

    // Green when perfect, primary color otherwise (80% opacity)
    final noteColor =
        isPerfect
            ? AppColors.paperOk.withValues(alpha: 0.9)
            : AppColors.paperAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Note name
        Text(
          displayNote.displayName,
          style: TextStyle(
            fontSize: noteFontSize,
            fontWeight: FontWeight.bold,
            color: noteColor,
          ),
        ),
        // Octave
        Text(
          '${displayNote.octave}',
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
