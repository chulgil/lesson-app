import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 3-step progress bar for paymentNotified waiting state.
///
/// Spec §3.2.4: 입금 알림 (v) → 확인 대기 (current) → 수강권 발급
///
/// Uses dashed connector + centered layout matching LessonProgressBar pattern.
class PaymentPendingProgressBar extends StatelessWidget {
  const PaymentPendingProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 1 — completed (입금 알림)
          _StepDot(
            label: AppStrings.paymentProgressStep1,
            state: _StepState.completed,
          ),
          // Connector 1→2
          const Expanded(
            child: CustomPaint(
              size: Size(double.infinity, 2),
              painter: _DashedLinePainter(color: AppColors.paperAccent),
            ),
          ),
          // Step 2 — active (확인 대기)
          _StepDot(
            label: AppStrings.paymentProgressStep2,
            state: _StepState.active,
          ),
          // Connector 2→3
          const Expanded(
            child: CustomPaint(
              size: Size(double.infinity, 2),
              painter: _DashedLinePainter(color: AppColors.inkQuaternary),
            ),
          ),
          // Step 3 — future (수강권 발급)
          _StepDot(
            label: AppStrings.paymentProgressStep3,
            state: _StepState.future,
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, active, future }

class _StepDot extends StatelessWidget {
  final String label;
  final _StepState state;

  static const _dotSize = 20.0;
  static const _ringSize = 28.0;

  const _StepDot({required this.label, required this.state});

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
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: _textColor,
              fontWeight: state == _StepState.active
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
      case _StepState.completed:
        return Container(
          width: _dotSize,
          height: _dotSize,
          decoration: const BoxDecoration(
            color: AppColors.paperAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: AppColors.paper),
        );

      case _StepState.active:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _ringSize,
              height: _ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );

      case _StepState.future:
        return Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.inkQuaternary, width: 1.5),
          ),
        );
    }
  }

  Color get _textColor => switch (state) {
    _StepState.completed => AppColors.paperAccent,
    _StepState.active => AppColors.ink,
    _StepState.future => AppColors.inkTertiary,
  };
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + dashWidth).clamp(0.0, size.width), y),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
