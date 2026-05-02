import 'package:flutter/material.dart';

import '../../features/schedule/domain/entities/unified_lesson_request.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 5-phase progress bar for the lesson lifecycle chapter model.
///
/// Displays: 신청 → 확정 → 입금 → 진행 → 완료
///
/// Visual encoding (standard stepper pattern):
/// - Completed: filled circle + checkmark (✓)
/// - Active: filled circle + outer ring
/// - Future: hollow circle (border only)
/// - Muted (terminal): hollow circle, muted color
class LessonProgressBar extends StatelessWidget {
  final RequestPhase currentPhase;

  const LessonProgressBar({super.key, required this.currentPhase});

  @override
  Widget build(BuildContext context) {
    final phases = _phases;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: List.generate(phases.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line between dots
            final phaseIndex = index ~/ 2;
            final isCompleted = phaseIndex < _currentIndex;
            return Expanded(
              child: CustomPaint(
                size: const Size(double.infinity, 2),
                painter: _DashedLinePainter(
                  color:
                      isCompleted
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                  strokeWidth: 1.5,
                  dashWidth: 4,
                  dashGap: 3,
                ),
              ),
            );
          }

          // Phase dot + label
          final phaseIndex = index ~/ 2;
          final phase = phases[phaseIndex];
          final state = _phaseState(phaseIndex);

          return _PhaseDot(label: phase.label, state: state);
        }),
      ),
    );
  }

  int get _currentIndex {
    return switch (currentPhase) {
      RequestPhase.request => 0,
      RequestPhase.subscription => 2,
      RequestPhase.lessons => 3,
      RequestPhase.completed => 4,
      RequestPhase.terminal => 0,
    };
  }

  _PhaseState _phaseState(int index) {
    if (currentPhase == RequestPhase.terminal) return _PhaseState.muted;
    final current = _currentIndex;
    if (index < current) return _PhaseState.completed;
    if (index == current) return _PhaseState.active;
    return _PhaseState.future;
  }

  List<_PhaseInfo> get _phases => const [
    _PhaseInfo(AppStrings.phaseRequest),
    _PhaseInfo(AppStrings.phaseConfirmed),
    _PhaseInfo(AppStrings.phasePayment),
    _PhaseInfo(AppStrings.phaseLessons),
    _PhaseInfo(AppStrings.phaseCompleted),
  ];
}

enum _PhaseState { completed, active, future, muted }

class _PhaseInfo {
  final String label;
  const _PhaseInfo(this.label);
}

/// Dashed line painter for future/incomplete connector segments.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashWidth).clamp(0, size.width), y),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

class _PhaseDot extends StatelessWidget {
  final String label;
  final _PhaseState state;

  static const _dotSize = 20.0;
  static const _ringSize = 28.0;

  const _PhaseDot({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ringSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: Center(child: _buildDot()),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: _textColor,
              fontWeight:
                  state == _PhaseState.active
                      ? FontWeight.w600
                      : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    switch (state) {
      case _PhaseState.completed:
        return Container(
          width: _dotSize,
          height: _dotSize,
          decoration: const BoxDecoration(
            color: AppColors.paperAccent,
            shape: BoxShape.circle,
          ),
          // Notebook × Score §7.50: Vermillion check glyph = paper.
          child: const Icon(Icons.check, size: 12, color: AppColors.paper),
        );

      case _PhaseState.active:
        // Filled dot + outer ring for emphasis
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: _ringSize,
              height: _ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paperAccentSoft, width: 2),
              ),
            ),
            // Inner filled dot
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: const BoxDecoration(
                color: AppColors.paperAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );

      case _PhaseState.future:
        // Hollow circle (border only)
        return Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.inkQuaternary, width: 1.5),
          ),
        );

      case _PhaseState.muted:
        // Hollow circle, muted color
        return Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.scheduleMutedAccent,
              width: 1.5,
            ),
          ),
        );
    }
  }

  Color get _textColor {
    switch (state) {
      case _PhaseState.completed:
      case _PhaseState.active:
        return AppColors.paperAccent;
      case _PhaseState.future:
      case _PhaseState.muted:
        return AppColors.inkTertiary;
    }
  }
}
