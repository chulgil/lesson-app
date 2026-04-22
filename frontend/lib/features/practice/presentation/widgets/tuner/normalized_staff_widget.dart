// Normalized staff widget for tuner
// Displays all notes in a single octave range (like CarlTune)

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';

/// Normalized staff widget that displays notes within a single octave range.
///
/// All notes are shown at their natural position on a treble clef staff,
/// with the octave number displayed separately. This avoids excessive
/// ledger lines for very high or low notes.
class NormalizedStaffWidget extends StatelessWidget {
  const NormalizedStaffWidget({
    super.key,
    required this.note,
    this.width = 120,
    this.height = 80,
    this.showOctave = true,
    this.isPerfect = false,
  });

  /// The note to display
  final TunerNote? note;

  /// Width of the staff widget
  final double width;

  /// Height of the staff widget
  final double height;

  /// Whether to show octave number
  final bool showOctave;

  /// Whether the tuning is perfect (changes color)
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _StaffPainter(
          note: note,
          showOctave: showOctave,
          isPerfect: isPerfect,
        ),
      ),
    );
  }
}

/// Custom painter for the normalized staff
class _StaffPainter extends CustomPainter {
  _StaffPainter({
    required this.note,
    required this.showOctave,
    required this.isPerfect,
  });

  final TunerNote? note;
  final bool showOctave;
  final bool isPerfect;

  // Staff line spacing (distance between lines)
  static const double lineSpacing = 8.0;

  // Note head dimensions
  static const double noteHeadWidth = 12.0;
  static const double noteHeadHeight = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Staff vertical range: 5 lines with 4 spaces between them
    // Total height = 4 * lineSpacing = 32px
    final staffTop = centerY - (lineSpacing * 2);

    // Draw staff lines
    _drawStaffLines(canvas, size, staffTop);

    // Draw treble clef symbol (simplified)
    _drawTrebleClef(canvas, staffTop);

    // Draw note if available
    if (note != null) {
      _drawNote(canvas, centerX + 15, staffTop, note!);
    }
  }

  void _drawStaffLines(Canvas canvas, Size size, double staffTop) {
    final linePaint = Paint()
      ..color = AppColors.inkTertiary
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw 5 horizontal lines
    for (var i = 0; i < 5; i++) {
      final y = staffTop + (i * lineSpacing);
      canvas.drawLine(
        Offset(10, y),
        Offset(size.width - 10, y),
        linePaint,
      );
    }
  }

  void _drawTrebleClef(Canvas canvas, double staffTop) {
    // Simplified treble clef using text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(
          fontSize: 38,
          color: AppColors.inkSecondary,
          fontFamily: 'Noto Music',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position clef at left side, vertically centered on staff
    textPainter.paint(
      canvas,
      Offset(8, staffTop - 10),
    );
  }

  void _drawNote(Canvas canvas, double centerX, double staffTop, TunerNote note) {
    // Get normalized Y position for the note
    final noteY = _getNoteY(note.name, staffTop);

    // Colors
    final noteColor = isPerfect ? AppColors.paperOk : AppColors.ink;
    final accentColor = isPerfect ? AppColors.paperOk : AppColors.inkSecondary;

    // Draw ledger lines if needed
    _drawLedgerLines(canvas, centerX, staffTop, note.name, noteColor);

    // Draw note head (filled ellipse)
    final notePaint = Paint()
      ..color = noteColor
      ..style = PaintingStyle.fill;

    // Note head is slightly tilted ellipse
    canvas.save();
    canvas.translate(centerX, noteY);
    canvas.rotate(-0.3); // Slight tilt
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteHeadWidth,
        height: noteHeadHeight,
      ),
      notePaint,
    );
    canvas.restore();

    // Draw accidental if needed
    if (note.name.isAccidental) {
      _drawAccidental(canvas, centerX - 14, noteY, note.name, accentColor);
    }

    // Draw octave number
    if (showOctave) {
      _drawOctave(canvas, centerX + 18, noteY, note.octave, accentColor);
    }
  }

  /// Get Y position for a note (normalized to single octave range)
  ///
  /// Positions (from top to bottom of staff):
  /// - B: 3rd line (middle line) - index 2 from top
  /// - A: 2nd space - between lines 2 and 3
  /// - G: 2nd line - index 1 from top
  /// - F: 1st space - between lines 1 and 2
  /// - E: 1st line (top line) - index 0 from top
  /// - D: space above staff
  /// - C: 1 ledger line above staff
  ///
  /// Wait, this is inverted. Let me reconsider:
  /// Standard treble clef (from bottom to top):
  /// - Line 1 (bottom): E
  /// - Space 1: F
  /// - Line 2: G
  /// - Space 2: A
  /// - Line 3: B
  /// - Space 3: C (middle C is below, C5 is here)
  /// - Line 4: D
  /// - Space 4: E
  /// - Line 5 (top): F
  ///
  /// For normalized display, I'll use positions relative to middle C (C4):
  /// - C: 1 ledger line below staff
  /// - D: space just below line 1
  /// - E: line 1 (bottom)
  /// - F: space 1
  /// - G: line 2
  /// - A: space 2
  /// - B: line 3 (middle line)
  double _getNoteY(NoteName name, double staffTop) {
    // staffTop is Y of the top line (line 5)
    // Line 5 (top) = staffTop
    // Line 4 = staffTop + lineSpacing
    // Line 3 = staffTop + lineSpacing * 2
    // Line 2 = staffTop + lineSpacing * 3
    // Line 1 (bottom) = staffTop + lineSpacing * 4

    // Normalized positions for C4-B4 range:
    // We want to display within a comfortable range
    // Using positions where:
    // C = 1 ledger line below (staffTop + lineSpacing * 5)
    // D = space below line 1 (staffTop + lineSpacing * 4.5)
    // E = line 1 (staffTop + lineSpacing * 4)
    // F = space 1 (staffTop + lineSpacing * 3.5)
    // G = line 2 (staffTop + lineSpacing * 3)
    // A = space 2 (staffTop + lineSpacing * 2.5)
    // B = line 3 (staffTop + lineSpacing * 2)

    final positions = <NoteName, double>{
      NoteName.C: staffTop + lineSpacing * 5,      // Ledger line below
      NoteName.Cs: staffTop + lineSpacing * 5,     // Same as C
      NoteName.D: staffTop + lineSpacing * 4.5,    // Space below line 1
      NoteName.Ds: staffTop + lineSpacing * 4.5,   // Same as D
      NoteName.E: staffTop + lineSpacing * 4,      // Line 1 (bottom)
      NoteName.F: staffTop + lineSpacing * 3.5,    // Space 1
      NoteName.Fs: staffTop + lineSpacing * 3.5,   // Same as F
      NoteName.G: staffTop + lineSpacing * 3,      // Line 2
      NoteName.Gs: staffTop + lineSpacing * 3,     // Same as G
      NoteName.A: staffTop + lineSpacing * 2.5,    // Space 2
      NoteName.As: staffTop + lineSpacing * 2.5,   // Same as A
      NoteName.B: staffTop + lineSpacing * 2,      // Line 3 (middle)
    };

    return positions[name] ?? staffTop + lineSpacing * 3;
  }

  void _drawLedgerLines(Canvas canvas, double centerX, double staffTop, NoteName name, Color color) {
    // C needs one ledger line below the staff
    if (name == NoteName.C || name == NoteName.Cs) {
      final ledgerY = staffTop + lineSpacing * 5;
      final ledgerPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(centerX - noteHeadWidth, ledgerY),
        Offset(centerX + noteHeadWidth, ledgerY),
        ledgerPaint,
      );
    }
  }

  void _drawAccidental(Canvas canvas, double x, double y, NoteName name, Color color) {
    // Draw sharp (#) or flat (b) symbol
    final isSharp = name.sharpName.contains('#');
    final symbol = isSharp ? '♯' : '♭';

    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawOctave(Canvas canvas, double x, double y, int octave, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$octave',
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) {
    return oldDelegate.note != note ||
        oldDelegate.isPerfect != isPerfect ||
        oldDelegate.showOctave != showOctave;
  }
}
