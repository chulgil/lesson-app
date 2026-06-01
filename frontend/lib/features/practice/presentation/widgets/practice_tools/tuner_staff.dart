import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_display_note.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';
import '../tuner/clef_svgs.dart';

/// Musical staff with note display for tuner.
/// Shows the current note on a 5-line staff when pitch is within beginner threshold.
/// Uses SVG for accurate clef rendering.
class TunerStaff extends ConsumerWidget {
  const TunerStaff({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final currentDisplayNote = ref.watch(currentDisplayNoteProvider);
    final clefType = tunerState.settings.clefType;
    final autoSwitchClef = tunerState.settings.autoSwitchClef;

    // Use beginner-level threshold (±20 cents) for staff display
    final isWithinBeginnerThreshold =
        currentNote != null &&
        currentNote.centDeviation.abs() <= TunerDifficulty.beginner.perfectCent;

    final displayNote = isWithinBeginnerThreshold ? currentDisplayNote : null;

    // Determine effective clef (auto-switch only if enabled in settings)
    final effectiveClef =
        displayNote != null
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

    // Clef-specific height (treble clef needs to be 1.5x bigger, bass clef slightly smaller)
    final clefHeight = switch (effectiveClef) {
      ClefType.treble => height * 0.85 * 1.5,
      ClefType.bass => height * 0.7, // Reduced from 0.85 for better proportion
      ClefType.alto => height * 0.85,
    };

    // Clef-specific left offset (treble clef needs to be more to the left)
    final clefLeftOffset = switch (effectiveClef) {
      ClefType.treble => -30.0,
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
          CustomPaint(size: Size(width, height), painter: StaffLinesPainter()),

          // Layer 2: Clef SVG (only set height, let width auto-calculate to preserve aspect ratio)
          Positioned(
            left: clefLeftOffset,
            top: (height - clefHeight) / 2,
            child: SvgPicture.string(
              clefSvg,
              height: clefHeight,
              colorFilter: ColorFilter.mode(
                AppColors.inkSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),

          // Layer 3: Note
          if (displayNote != null)
            CustomPaint(
              size: Size(width, height),
              painter: NotePainter(
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
  /// Automatically switches to bass clef for low notes (C3 and below in treble)
  /// to avoid notes going too far below the staff.
  ClefType _getEffectiveClef(
    TunerDisplayNote note,
    ClefType preferredClef,
    bool autoSwitch,
  ) {
    final naturalName = note.staffNaturalName;

    // Always auto-switch for very low/high notes to keep them on staff
    // For treble clef: switch to bass for notes below E3
    if (preferredClef == ClefType.treble && note.octave <= 3) {
      if (note.octave < 3 ||
          (note.octave == 3 && 'CDEF'.contains(naturalName))) {
        return ClefType.bass;
      }
    }

    // For bass clef: switch to treble for notes above A3
    if (preferredClef == ClefType.bass && note.octave >= 4) {
      return ClefType.treble;
    }

    // If auto-switch is disabled, use preferred clef for mid-range notes
    if (!autoSwitch) {
      return preferredClef;
    }

    // Auto-switch mode: check if note is in preferred clef range first
    final preferredPositions = getPositionsForClef(preferredClef);
    final noteKey = '$naturalName${note.octave}';
    if (preferredPositions.containsKey(noteKey)) {
      return preferredClef;
    }

    // Try other clefs if note is outside preferred clef range
    for (final clef in ClefType.values) {
      if (clef == preferredClef) continue;
      final positions = getPositionsForClef(clef);
      if (positions.containsKey(noteKey)) {
        return clef;
      }
    }

    return preferredClef; // Fallback
  }
}

/// Get note positions for a specific clef.
Map<String, double> getPositionsForClef(ClefType clef) {
  switch (clef) {
    case ClefType.treble:
      return {
        'C3': 9.5,
        'D3': 9.0,
        'E3': 8.5,
        'F3': 8.0,
        'G3': 7.5,
        'A3': 7.0,
        'B3': 6.5,
        'C4': 6.0,
        'D4': 5.5,
        'E4': 5.0,
        'F4': 4.5,
        'G4': 4.0,
        'A4': 3.5,
        'B4': 3.0,
        'C5': 2.5,
        'D5': 2.0,
        'E5': 1.5,
        'F5': 1.0,
        'G5': 0.5,
        'A5': 0.0,
        'B5': -0.5,
        'C6': -1.0,
        'D6': -1.5,
        'E6': -2.0,
        'F6': -2.5,
        'G6': -3.0,
        'A6': -3.5,
        'B6': -4.0,
      };
    case ClefType.bass:
      // Bass clef: G2 on line 1 (bottom=5.0), D3 on line 3 (middle=3.0), A3 on line 5 (top=1.0)
      return {
        'E1': 9.5,
        'F1': 9.0,
        'G1': 8.5,
        'A1': 8.0,
        'B1': 7.5,
        'C2': 7.0,
        'D2': 6.5,
        'E2': 6.0,
        'F2': 5.5,
        'G2': 5.0,
        'A2': 4.5,
        'B2': 4.0,
        'C3': 3.5,
        'D3': 3.0,
        'E3': 2.5,
        'F3': 2.0,
        'G3': 1.5,
        'A3': 1.0,
        'B3': 0.5,
        'C4': 0.0,
        'D4': -0.5,
        'E4': -1.0,
        'F4': -1.5,
        'G4': -2.0,
        'A4': -2.5,
        'B4': -3.0,
      };
    case ClefType.alto:
      // Alto clef: F3 on line 1 (bottom), C4 on line 3 (middle), G4 on line 5 (top)
      return {
        'C2': 10.0,
        'D2': 9.5,
        'E2': 9.0,
        'F2': 8.5,
        'G2': 8.0,
        'A2': 7.5,
        'B2': 7.0,
        'C3': 6.5,
        'D3': 6.0,
        'E3': 5.5,
        'F3': 5.0,
        'G3': 4.5,
        'A3': 4.0,
        'B3': 3.5,
        'C4': 3.0,
        'D4': 2.5,
        'E4': 2.0,
        'F4': 1.5,
        'G4': 1.0,
        'A4': 0.5,
        'B4': 0.0,
        'C5': -0.5,
        'D5': -1.0,
        'E5': -1.5,
        'F5': -2.0,
        'G5': -2.5,
        'A5': -3.0,
        'B5': -3.5,
      };
  }
}

/// Painter for staff lines only.
class StaffLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.inkTertiary
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
class NotePainter extends CustomPainter {
  NotePainter({
    required this.note,
    required this.effectiveClef,
    required this.lineSpacing,
  });

  final TunerDisplayNote note;
  final ClefType effectiveClef;
  final double lineSpacing;

  /// Calculate position for any note, even if outside predefined range.
  double _getPositionForNote(String naturalName, int octave) {
    final positions = getPositionsForClef(effectiveClef);
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
    final naturalName = note.staffNaturalName;
    final position = _getPositionForNote(naturalName, note.octave);

    final y = position * lineSpacing;
    final x = size.width * 0.7; // Note in right portion
    final noteRadius = lineSpacing * 0.55;

    // Draw note head
    final notePaint =
        Paint()
          ..color = AppColors.paperAccent
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
    final stemPaint =
        Paint()
          ..color = AppColors.paperAccent
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
    final ledgerPaint =
        Paint()
          ..color = AppColors.inkTertiary
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

    // Draw accidental symbol if needed
    if (note.staffAccidental != TunerAccidental.natural) {
      final accidentalPaint =
          Paint()
            ..color = AppColors.paperAccent
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      final accidentalX = x - noteRadius * 2.5;
      final accidentalSize = lineSpacing * 0.5;

      if (note.staffAccidental == TunerAccidental.sharp) {
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
      } else {
        final path =
            Path()
              ..moveTo(accidentalX - accidentalSize * 0.15, y - accidentalSize)
              ..lineTo(accidentalX - accidentalSize * 0.15, y + accidentalSize)
              ..quadraticBezierTo(
                accidentalX + accidentalSize * 0.6,
                y + accidentalSize * 0.15,
                accidentalX - accidentalSize * 0.15,
                y,
              );
        canvas.drawPath(path, accidentalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant NotePainter oldDelegate) {
    return oldDelegate.note != note ||
        oldDelegate.effectiveClef != effectiveClef;
  }
}
