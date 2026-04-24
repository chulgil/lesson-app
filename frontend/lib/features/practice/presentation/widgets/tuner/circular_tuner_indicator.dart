import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';
import 'tuner_fish_indicator.dart';

/// Colors for tuner indicator (delegates to AppColors).
class TunerColors {
  TunerColors._();

  static const glowPerfect = AppColors.tunerGlowPerfect;
  static const circleStroke = AppColors.tunerCircleStroke;
}

/// Circular 12-note tuner indicator widget.
///
/// Displays all 12 chromatic notes in a circle with:
/// - Color coding for natural vs accidental notes
/// - Active note highlighting with glow effect
/// - Enharmonic display option (C#/Db)
class CircularTunerIndicator extends ConsumerWidget {
  const CircularTunerIndicator({super.key, this.size = 280, this.centerChild});

  /// Size of the indicator (diameter).
  final double size;

  /// Widget to display in the center (e.g., cat indicator).
  final Widget? centerChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final settings = tunerState.settings;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none, // Allow indicators to overflow outside
        alignment: Alignment.center,
        children: [
          // Background circle (centered, original size)
          CustomPaint(
            size: Size(size, size),
            painter: _CircleBackgroundPainter(),
          ),

          // Note labels around the circle (tappable for future sound playback)
          for (var i = 0; i < NoteName.values.length; i++)
            _NoteLabel(
              key: ValueKey('note_${i}_$size'), // Force rebuild on size change
              note: NoteName.values[i],
              index: i,
              totalNotes: NoteName.values.length,
              circleSize: size,
              enharmonicMode: settings.enharmonicMode,
              onTap: () {
                // TODO: Play note sound when tapped
              },
            ),

          // Fish indicator (follows around the circle)
          TunerFishIndicator(circleSize: size),

          // Center content (uses its own size, not constrained)
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }
}

/// Background circle painter.
class _CircleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10; // Circle close to edge (1.4x bigger)

    final paint =
        Paint()
          ..color = TunerColors.circleStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Individual note label widget.
class _NoteLabel extends ConsumerStatefulWidget {
  const _NoteLabel({
    super.key,
    required this.note,
    required this.index,
    required this.totalNotes,
    required this.circleSize,
    required this.enharmonicMode,
    this.onTap,
  });

  final NoteName note;
  final int index;
  final int totalNotes;
  final double circleSize;
  final EnharmonicMode enharmonicMode;
  final VoidCallback? onTap;

  @override
  ConsumerState<_NoteLabel> createState() => _NoteLabelState();
}

class _NoteLabelState extends ConsumerState<_NoteLabel> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    // Watch tuner state for perfect highlight
    final tunerState = ref.watch(tunerProvider);
    final isPerfectMatch =
        tunerState.isPerfect && tunerState.currentNote?.name == widget.note;
    // Calculate position on circle
    // Start from top (12 o'clock = C) and go clockwise
    final angle =
        (2 * math.pi * widget.index / widget.totalNotes) - (math.pi / 2);
    final radius = widget.circleSize / 2 - 25; // Position inside the circle

    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    // Get display text
    final displayText = _getDisplayText();

    // Determine colors
    final baseColor =
        widget.note.isAccidental
            ? AppColors.tunerAccidentalNote
            : AppColors.tunerNaturalNote;
    final activeColor =
        widget.note.isAccidental
            ? AppColors.tunerAccidentalNoteActive
            : AppColors.tunerNaturalNoteActive;

    // Scale sizes based on circle size (base size 280), increased by 1.2x
    final scale = widget.circleSize / 280.0;
    final normalFontSize = 14.4 * scale; // 12 * 1.2
    final tappedFontSize = 16.8 * scale; // 14 * 1.2
    final horizontalPadding = 10.8 * scale; // 9 * 1.2
    final verticalPadding = 6.0 * scale; // 5 * 1.2

    // Only change style when tapped, not on pitch match
    final isEnlarged = _isTapped;

    // Color logic: highlight on perfect pitch match (instant, no animation)
    Color backgroundColor;
    Color textColor;
    List<BoxShadow>? boxShadow;

    if (_isTapped) {
      // Tapped: darker color (no border)
      backgroundColor = activeColor;
      textColor = Colors.white;
    } else if (isPerfectMatch) {
      // Perfect pitch match: instant bright highlight with subtle glow
      backgroundColor = AppColors.tunerCentPerfect.withValues(alpha: 0.7);
      textColor = AppColors.paperOk;
      boxShadow = [
        BoxShadow(
          color: AppColors.tunerCentPerfect.withValues(alpha: 0.5),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    } else {
      // Normal style
      backgroundColor = baseColor.withValues(alpha: 0.3);
      textColor = AppColors.inkSecondary;
    }

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isTapped = true),
        onTapUp: (_) {
          setState(() => _isTapped = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isTapped = false),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: boxShadow,
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: isEnlarged ? tappedFontSize : normalFontSize,
              fontWeight: isEnlarged ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    switch (widget.enharmonicMode) {
      case EnharmonicMode.sharpOnly:
        return widget.note.sharpName;
      case EnharmonicMode.flatOnly:
        return widget.note.flatName;
      case EnharmonicMode.both:
        return widget.note.isAccidental
            ? widget.note.enharmonicName
            : widget.note.sharpName;
    }
  }
}

/// Cent gauge showing flat/sharp deviation.
class TunerCentGauge extends ConsumerWidget {
  const TunerCentGauge({super.key, this.width = 200, this.height = 30});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final centDeviation = tunerState.centDeviation;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CentGaugePainter(centDeviation: centDeviation),
      ),
    );
  }
}

class _CentGaugePainter extends CustomPainter {
  _CentGaugePainter({required this.centDeviation});

  final double centDeviation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxWidth = size.width / 2 - 10;

    // Background track
    final trackPaint =
        Paint()
          ..color = AppColors.inkQuaternary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(10, center.dy),
      Offset(size.width - 10, center.dy),
      trackPaint,
    );

    // Center marker
    final centerMarkerPaint =
        Paint()
          ..color = AppColors.tunerCentPerfect
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      centerMarkerPaint,
    );

    // Deviation indicator
    if (centDeviation != 0) {
      // Normalize cent to -50 to +50 range
      final normalizedCent = centDeviation.clamp(-50.0, 50.0);
      final indicatorX = center.dx + (normalizedCent / 50) * maxWidth;

      // Color based on deviation (flat=red, sharp=orange)
      final indicatorColor =
          centDeviation < 0
              ? AppColors.tunerCentFlat
              : AppColors.tunerCentSharp;

      final indicatorPaint =
          Paint()
            ..color = indicatorColor
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(indicatorX, center.dy), 8, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CentGaugePainter oldDelegate) {
    return oldDelegate.centDeviation != centDeviation;
  }
}

/// Tuner info bar showing reference frequency and cent deviation.
/// Line 1: "A4=442Hz" (fixed reference)
/// Line 2: "+5¢" (cent deviation)
class TunerInfoBar extends ConsumerWidget {
  const TunerInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final settings = tunerState.settings;
    final note = tunerState.currentNote;

    // Line 1: Reference frequency (always shown)
    final freqText = 'A4=${settings.referenceFrequency.toStringAsFixed(0)}Hz';

    // Line 2: Cent deviation (shown when note detected)
    final centText = note != null ? '${note.centDisplayString}¢' : '--';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            freqText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            centText,
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  note != null
                      ? (tunerState.isPerfect
                          ? AppColors.paperOk
                          : (note.centDeviation < 0
                              ? AppColors.tunerCentFlat
                              : AppColors.tunerCentSharp))
                      : AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
