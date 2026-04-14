import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Visual progress bar showing session completion status.
///
/// Pixel-exact match with [LessonProgressBar]:
/// - Expanded connectors (dashed/solid) filling available width
/// - Center-aligned dots (20px) with outer ring (28px) for active
/// - Completed: primary filled + checkmark
/// - Active: primary filled + primaryLight ring
/// - Future: hollow circle (borderLight)
/// - Labels below each dot (fontSize: 10)
class SessionProgressBar extends StatelessWidget {
  final int totalSessions;
  final int completedSessions;
  final int selectedSession;
  final Set<int> changeRequestedSessions;
  final bool isMonthly;
  final ValueChanged<int> onSessionTap;
  final VoidCallback? onBulkChangeTap;

  const SessionProgressBar({
    super.key,
    required this.totalSessions,
    required this.completedSessions,
    required this.selectedSession,
    this.changeRequestedSessions = const {},
    this.isMonthly = false,
    required this.onSessionTap,
    this.onBulkChangeTap,
  });

  // Matches LessonProgressBar._dotSize / _ringSize exactly
  static const double _dotSize = 20.0;
  static const double _ringSize = 28.0;
  static const int _maxPerRow = 8;

  @override
  Widget build(BuildContext context) {
    final sessions = List.generate(totalSessions, (index) => index + 1);
    final rows = _splitRows(sessions);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space2),
            _buildConnectedRow(rows[i], showBulkButton: i == 0 && isMonthly),
          ],
        ],
      ),
    );
  }

  List<List<int>> _splitRows(List<int> sessions) {
    final rows = <List<int>>[];
    final firstRowCount = isMonthly ? _maxPerRow - 1 : _maxPerRow;
    final firstRow = sessions.take(firstRowCount).toList();
    final remaining = sessions.skip(firstRowCount).toList();

    rows.add(firstRow);

    for (int i = 0; i < remaining.length; i += _maxPerRow) {
      final end = (i + _maxPerRow < remaining.length)
          ? i + _maxPerRow
          : remaining.length;
      rows.add(remaining.sublist(i, end));
    }

    return rows;
  }

  /// Build a row of session dots connected by Expanded dashed/solid lines.
  /// Matches LessonProgressBar's Row(children: [dot, Expanded(line), dot, ...])
  Widget _buildConnectedRow(
    List<int> sessions, {
    bool showBulkButton = false,
  }) {
    final itemCount = sessions.length * 2 - 1;

    return Row(
      children: [
        for (int i = 0; i < itemCount; i++) ...[
          if (i.isOdd)
            // Expanded connector — matches LessonProgressBar exactly
            _buildConnector(sessions[i ~/ 2]),
          if (i.isEven)
            _SessionDot(
              sessionNumber: sessions[i ~/ 2],
              state: _getState(sessions[i ~/ 2]),
              isSelected: sessions[i ~/ 2] == selectedSession,
              hasChangeRequest:
                  changeRequestedSessions.contains(sessions[i ~/ 2]),
              onTap: () => onSessionTap(sessions[i ~/ 2]),
            ),
        ],
        if (showBulkButton) ...[
          const SizedBox(width: AppSpacing.space2),
          _BulkChangeButton(onTap: onBulkChangeTap),
        ],
      ],
    );
  }

  /// Expanded connector: solid (primary) if completed, dashed (borderLight) otherwise.
  /// Exactly matches LessonProgressBar's connector pattern.
  Widget _buildConnector(int sessionNumber) {
    final isCompleted = sessionNumber <= completedSessions;

    return Expanded(
      child: isCompleted
          ? Container(height: 2, color: AppColors.primary)
          : CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _DashedLinePainter(
                color: AppColors.borderLight,
                strokeWidth: 1.5,
                dashWidth: 4,
                dashGap: 3,
              ),
            ),
    );
  }

  _SessionState _getState(int sessionNumber) {
    if (sessionNumber <= completedSessions) return _SessionState.completed;
    if (sessionNumber == selectedSession) return _SessionState.scheduled;
    return _SessionState.future;
  }
}

enum _SessionState { completed, scheduled, future }

/// Session dot — pixel-exact match with LessonProgressBar._PhaseDot.
class _SessionDot extends StatelessWidget {
  final int sessionNumber;
  final _SessionState state;
  final bool isSelected;
  final bool hasChangeRequest;
  final VoidCallback onTap;

  const _SessionDot({
    required this.sessionNumber,
    required this.state,
    required this.isSelected,
    required this.hasChangeRequest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: SessionProgressBar._ringSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: SessionProgressBar._ringSize,
              height: SessionProgressBar._ringSize,
              child: Center(child: _buildDot()),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.sessionNumberLabel(sessionNumber),
              style: AppTypography.caption.copyWith(
                color: _textColor,
                fontWeight: state == _SessionState.scheduled || isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildDotContent(),
        if (hasChangeRequest)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: AppSpacing.space2,
              height: AppSpacing.space2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDotContent() {
    switch (state) {
      // Completed: primary filled + checkmark (matches LessonProgressBar)
      case _SessionState.completed:
        return Container(
          width: SessionProgressBar._dotSize,
          height: SessionProgressBar._dotSize,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: Colors.white,
          ),
        );

      // Active: outer ring (primaryLight) + inner filled (primary)
      case _SessionState.scheduled:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: SessionProgressBar._ringSize,
              height: SessionProgressBar._ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight,
                  width: 2,
                ),
              ),
            ),
            Container(
              width: SessionProgressBar._dotSize,
              height: SessionProgressBar._dotSize,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );

      // Future: hollow circle (no text inside, matches LessonProgressBar)
      case _SessionState.future:
        return Container(
          width: SessionProgressBar._dotSize,
          height: SessionProgressBar._dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.borderLight,
              width: 1.5,
            ),
          ),
        );
    }
  }

  Color get _textColor {
    switch (state) {
      case _SessionState.completed:
      case _SessionState.scheduled:
        return AppColors.primary;
      case _SessionState.future:
        return isSelected ? AppColors.primary : AppColors.textTertiaryLight;
    }
  }
}

/// Dashed line painter — identical to LessonProgressBar._DashedLinePainter.
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
    final paint = Paint()
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

class _BulkChangeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _BulkChangeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: SessionProgressBar._ringSize,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Text(
            AppStrings.bulkChangeAll,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
