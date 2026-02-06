import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/tuner_types.dart';
import '../../providers/tuner_combo_provider.dart';
import 'tuner_cat_painters.dart';

/// Status message bubble for tuner.
class StatusBubble extends StatelessWidget {
  const StatusBubble({
    super.key,
    required this.isListening,
    required this.hasNote,
    required this.isPerfect,
  });

  final bool isListening;
  final bool hasNote;
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    String message;
    Color backgroundColor;
    Color textColor;

    if (!isListening) {
      message = '마이크를 켜주세요';
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    } else if (!hasNote) {
      message = '소리 감지 대기...';
      backgroundColor = Colors.blue[50]!;
      textColor = Colors.blue[700]!;
    } else if (isPerfect) {
      message = '완벽해요! 🎵';
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
    } else {
      message = '소리 감지중';
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Speech bubble that appears next to cat face.
class CatSpeechBubble extends StatelessWidget {
  const CatSpeechBubble({
    super.key,
    required this.isListening,
    this.hasNote = false,
    this.isPerfect = false,
    this.comboTier = ComboTier.none,
    this.scale = 1.0,
    this.centDeviation = 0.0,
  });

  final bool isListening;
  final bool hasNote;
  final bool isPerfect;
  final ComboTier comboTier;
  final double scale;
  final double centDeviation;

  @override
  Widget build(BuildContext context) {
    String message;
    Color backgroundColor;
    Color textColor;

    if (!isListening) {
      message = '마이크를 켜주세요';
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[600]!;
    } else if (!hasNote) {
      message = '소리 감지 대기...';
      backgroundColor = AppColors.bubbleIdleBackground;
      textColor = AppColors.bubbleIdleText;
    } else if (isPerfect) {
      // Use combo message if available
      message = comboTier != ComboTier.none ? comboTier.message : '완벽해요! 🎵';
      backgroundColor = AppColors.bubbleSuccessBackground;
      textColor = AppColors.bubbleSuccessText;
    } else {
      // Show direction message with arrow
      // If flat (negative cent): need to go up
      // If sharp (positive cent): need to go down
      if (centDeviation < 0) {
        message = '조금만 더 위로 ↑';
      } else {
        message = '조금만 더 아래로 ↓';
      }
      backgroundColor = AppColors.bubbleWarningBackground;
      textColor = AppColors.bubbleWarningText;
    }

    // Apply 1.1x size multiplier
    final adjustedScale = scale * 1.1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * adjustedScale,
        vertical: 8 * adjustedScale,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20 * adjustedScale), // More rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 10 * adjustedScale,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Cat face with expression based on tuning status.
class CatFace extends StatelessWidget {
  const CatFace({
    super.key,
    required this.size,
    required this.status,
    required this.isPerfect,
    required this.comboTier,
    this.isEcstatic = false,
  });

  final double size;
  final TuningStatus status;
  final bool isPerfect;
  final ComboTier comboTier;
  final bool isEcstatic;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CatFacePainter(
        status: status,
        isPerfect: isPerfect,
        comboTier: comboTier,
        isEcstatic: isEcstatic,
      ),
    );
  }
}

/// Note display with cent (note above, cent below).
class NoteWithCent extends StatelessWidget {
  const NoteWithCent({
    super.key,
    required this.note,
    required this.isPerfect,
  });

  final TunerNote note;
  final bool isPerfect;

  @override
  Widget build(BuildContext context) {
    final noteColor = isPerfect ? Colors.green : AppColors.primary;
    final centColor = isPerfect
        ? Colors.green
        : (note.centDeviation < 0 ? Colors.red : Colors.orange);

    final centText = '${note.centDeviation >= 0 ? '+' : ''}${note.centDeviation.toStringAsFixed(0)}¢';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Note name with octave (horizontal)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Note name (large)
            Text(
              note.name.sharpName,
              style: TextStyle(
                fontSize: 72,  // Increased to 72
                fontWeight: FontWeight.bold,
                color: noteColor,
              ),
            ),
            // Octave
            Text(
              '${note.octave}',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: noteColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        // Cent deviation (below, closer)
        Text(
          centText,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: centColor,
          ),
        ),
      ],
    );
  }
}
