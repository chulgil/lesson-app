import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_settings.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_provider.dart';

/// Colors for tuner indicator.
class TunerColors {
  TunerColors._();

  // Natural notes (C, D, E, F, G, A, B) - blue-ish tones
  static const naturalNote = Color(0xFFB8D4E3);
  static const naturalNoteActive = Color(0xFF6BA3C7);

  // Accidental notes (C#, D#, F#, G#, A#) - green-ish tones
  static const accidentalNote = Color(0xFFB8E3C8);
  static const accidentalNoteActive = Color(0xFF6BC790);

  // Cent gauge colors
  static const centPerfect = Color(0xFF90EE90);
  static const centFlat = Color(0xFFFF6B6B);
  static const centSharp = Color(0xFFFFB347);

  // Effects
  static const glowPerfect = Color(0x6690EE90);
  static const circleStroke = Color(0x33808080);
}

/// Circular 12-note tuner indicator widget.
///
/// Displays all 12 chromatic notes in a circle with:
/// - Color coding for natural vs accidental notes
/// - Active note highlighting with glow effect
/// - Enharmonic display option (C#/Db)
class CircularTunerIndicator extends ConsumerWidget {
  const CircularTunerIndicator({
    super.key,
    this.size = 280,
    this.centerChild,
  });

  /// Size of the indicator (diameter).
  final double size;

  /// Widget to display in the center (e.g., cat indicator).
  final Widget? centerChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final currentNote = tunerState.currentNote;
    final settings = tunerState.settings;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleBackgroundPainter(),
          ),

          // Note labels around the circle
          for (var i = 0; i < NoteName.values.length; i++)
            _NoteLabel(
              note: NoteName.values[i],
              index: i,
              totalNotes: NoteName.values.length,
              circleSize: size,
              isActive: currentNote?.name == NoteName.values[i],
              isPerfect:
                  currentNote?.name == NoteName.values[i] && tunerState.isPerfect,
              enharmonicMode: settings.enharmonicMode,
            ),

          // Active note glow effect
          if (currentNote != null && tunerState.isPerfect)
            _GlowEffect(
              noteIndex: currentNote.name.index,
              totalNotes: NoteName.values.length,
              circleSize: size,
            ),

          // Center content
          if (centerChild != null)
            SizedBox(
              width: size * 0.45,
              height: size * 0.45,
              child: centerChild,
            ),
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
    final radius = size.width / 2 - 30; // Leave room for note labels

    final paint = Paint()
      ..color = TunerColors.circleStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Individual note label widget.
class _NoteLabel extends StatelessWidget {
  const _NoteLabel({
    required this.note,
    required this.index,
    required this.totalNotes,
    required this.circleSize,
    required this.isActive,
    required this.isPerfect,
    required this.enharmonicMode,
  });

  final NoteName note;
  final int index;
  final int totalNotes;
  final double circleSize;
  final bool isActive;
  final bool isPerfect;
  final EnharmonicMode enharmonicMode;

  @override
  Widget build(BuildContext context) {
    // Calculate position on circle
    // Start from top (12 o'clock = C) and go clockwise
    final angle = (2 * math.pi * index / totalNotes) - (math.pi / 2);
    final radius = circleSize / 2 - 25; // Position near edge

    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    // Get display text
    final displayText = _getDisplayText();

    // Determine colors
    final baseColor =
        note.isAccidental ? TunerColors.accidentalNote : TunerColors.naturalNote;
    final activeColor = note.isAccidental
        ? TunerColors.accidentalNoteActive
        : TunerColors.naturalNoteActive;

    return Transform.translate(
      offset: Offset(x, y),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : baseColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(
                  color: isPerfect ? TunerColors.glowPerfect : activeColor,
                  width: isPerfect ? 3 : 2,
                )
              : null,
          boxShadow: isPerfect
              ? [
                  BoxShadow(
                    color: TunerColors.glowPerfect,
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: isActive ? 14 : 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    switch (enharmonicMode) {
      case EnharmonicMode.sharpOnly:
        return note.sharpName;
      case EnharmonicMode.flatOnly:
        return note.flatName;
      case EnharmonicMode.both:
        return note.isAccidental ? note.enharmonicName : note.sharpName;
    }
  }
}

/// Glow effect for perfect tuning.
class _GlowEffect extends StatefulWidget {
  const _GlowEffect({
    required this.noteIndex,
    required this.totalNotes,
    required this.circleSize,
  });

  final int noteIndex;
  final int totalNotes;
  final double circleSize;

  @override
  State<_GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<_GlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate position
    final angle =
        (2 * math.pi * widget.noteIndex / widget.totalNotes) - (math.pi / 2);
    final radius = widget.circleSize / 2 - 25;

    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: TunerColors.glowPerfect.withValues(alpha: _animation.value),
                  blurRadius: 20 * _animation.value,
                  spreadRadius: 5 * _animation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cent gauge showing flat/sharp deviation.
class TunerCentGauge extends ConsumerWidget {
  const TunerCentGauge({
    super.key,
    this.width = 200,
    this.height = 30,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final centDeviation = tunerState.centDeviation;
    final isPerfect = tunerState.isPerfect;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CentGaugePainter(
          centDeviation: centDeviation,
          isPerfect: isPerfect,
        ),
      ),
    );
  }
}

class _CentGaugePainter extends CustomPainter {
  _CentGaugePainter({
    required this.centDeviation,
    required this.isPerfect,
  });

  final double centDeviation;
  final bool isPerfect;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxWidth = size.width / 2 - 10;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(10, center.dy),
      Offset(size.width - 10, center.dy),
      trackPaint,
    );

    // Center marker
    final centerMarkerPaint = Paint()
      ..color = TunerColors.centPerfect
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      centerMarkerPaint,
    );

    // Deviation indicator
    if (centDeviation != 0 || isPerfect) {
      // Normalize cent to -50 to +50 range
      final normalizedCent = centDeviation.clamp(-50.0, 50.0);
      final indicatorX = center.dx + (normalizedCent / 50) * maxWidth;

      // Color based on deviation
      Color indicatorColor;
      if (isPerfect) {
        indicatorColor = TunerColors.centPerfect;
      } else if (centDeviation < 0) {
        indicatorColor = TunerColors.centFlat;
      } else {
        indicatorColor = TunerColors.centSharp;
      }

      final indicatorPaint = Paint()
        ..color = indicatorColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(indicatorX, center.dy),
        isPerfect ? 10 : 8,
        indicatorPaint,
      );

      // Glow for perfect
      if (isPerfect) {
        final glowPaint = Paint()
          ..color = TunerColors.glowPerfect
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(indicatorX, center.dy),
          15,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CentGaugePainter oldDelegate) {
    return oldDelegate.centDeviation != centDeviation ||
        oldDelegate.isPerfect != isPerfect;
  }
}

/// Tuner info bar showing "A4 · 442Hz · +5¢".
class TunerInfoBar extends ConsumerWidget {
  const TunerInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoDisplay = ref.watch(tunerInfoDisplayProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        infoDisplay,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
