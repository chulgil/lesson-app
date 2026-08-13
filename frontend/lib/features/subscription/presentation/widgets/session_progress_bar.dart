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
/// - Labels below each dot (AppTypography.captionSmall)
class SessionProgressBar extends StatelessWidget {
  final int totalSessions;
  final int completedSessions;
  final int selectedSession;
  final Set<int> changeRequestedSessions;
  final bool isMonthly;
  final ValueChanged<int> onSessionTap;

  const SessionProgressBar({
    super.key,
    required this.totalSessions,
    required this.completedSessions,
    required this.selectedSession,
    this.changeRequestedSessions = const {},
    this.isMonthly = false,
    required this.onSessionTap,
  });

  // Matches LessonProgressBar._dotSize / _ringSize exactly
  static const double _dotSize = 20.0;
  static const double _ringSize = 28.0;
  static const int _maxPerRow = 8;

  @override
  Widget build(BuildContext context) {
    // 항상 8칸 고정 레이아웃
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: _buildFixedEightRow(),
    );
  }

  /// 항상 8칸 고정 레이아웃.
  /// - 1~12회차: 실제 회차에 번호 표기, 나머지 빈 칸도 dot으로 표기
  /// - 12회차 초과: 슬라이딩 윈도우, 빈 칸은 번호 미표기
  Widget _buildFixedEightRow() {
    final List<int?> displaySlots = List.filled(_maxPerRow, null);

    if (totalSessions <= 12) {
      // 1~12회차: 실제 세션만 번호 표기, 나머지 칸은 빈 dot
      for (int i = 0; i < _maxPerRow && i < totalSessions; i++) {
        displaySlots[i] = i + 1;
      }
    } else {
      // 12회차 초과: 현재 위치 기준 슬라이딩 윈도우
      final activeSession = selectedSession.clamp(1, totalSessions);
      final maxStart = totalSessions - _maxPerRow + 1;
      int windowStart = (activeSession - 4).clamp(
        1,
        maxStart > 0 ? maxStart : 1,
      );
      for (int i = 0; i < _maxPerRow; i++) {
        final sessionNum = windowStart + i;
        if (sessionNum <= totalSessions) {
          displaySlots[i] = sessionNum;
        }
      }
    }

    return Row(
      children: [
        for (int i = 0; i < _maxPerRow; i++) ...[
          if (i > 0)
            _buildConnector(
              displaySlots[i] ?? (displaySlots[i - 1] ?? 0) + 1,
              isEmpty: displaySlots[i] == null,
            ),
          _SessionDot(
            sessionNumber: displaySlots[i] ?? 0,
            state:
                displaySlots[i] != null
                    ? _getState(displaySlots[i]!)
                    : _SessionState.future,
            isSelected: displaySlots[i] == selectedSession,
            hasChangeRequest:
                displaySlots[i] != null &&
                changeRequestedSessions.contains(displaySlots[i]),
            onTap: () {
              if (displaySlots[i] != null) onSessionTap(displaySlots[i]!);
            },
            // 실제 세션이 할당된 칸만 번호 표기, 빈 칸(null)은 번호 없음
            showLabel: displaySlots[i] != null,
          ),
        ],
      ],
    );
  }

  /// Expanded connector: primary if completed, borderLight if assigned, lighter grey if empty slot.
  Widget _buildConnector(int sessionNumber, {bool isEmpty = false}) {
    final isCompleted = !isEmpty && sessionNumber <= completedSessions;

    final Color color;
    if (isCompleted) {
      color = AppColors.paperAccent;
    } else if (isEmpty) {
      color = AppColors.inkMuted;
    } else {
      color = AppColors.inkQuaternary;
    }

    return Expanded(
      child: CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DashedLinePainter(
          color: color,
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
  final bool showLabel;

  const _SessionDot({
    required this.sessionNumber,
    required this.state,
    required this.isSelected,
    required this.hasChangeRequest,
    required this.onTap,
    this.showLabel = true,
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
              showLabel && sessionNumber > 0
                  ? AppStrings.sessionNumberLabel(sessionNumber)
                  : '',
              style: AppTypography.captionSmall.copyWith(
                color: _textColor,
                fontWeight:
                    state == _SessionState.scheduled || isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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
              decoration: const BoxDecoration(color: AppColors.paperAccent),
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
          decoration: const BoxDecoration(color: AppColors.paperAccent),
          child: const Icon(Icons.check, size: 12, color: AppColors.paper),
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
                border: Border.all(color: AppColors.paperAccentSoft, width: 2),
              ),
            ),
            Container(
              width: SessionProgressBar._dotSize,
              height: SessionProgressBar._dotSize,
              decoration: const BoxDecoration(color: AppColors.paperAccent),
            ),
          ],
        );

      // Future: hollow circle (no text inside, matches LessonProgressBar)
      case _SessionState.future:
        return Container(
          width: SessionProgressBar._dotSize,
          height: SessionProgressBar._dotSize,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inkQuaternary, width: 1.5),
          ),
        );
    }
  }

  Color get _textColor {
    switch (state) {
      case _SessionState.completed:
      case _SessionState.scheduled:
        return AppColors.paperAccent;
      case _SessionState.future:
        return isSelected ? AppColors.paperAccent : AppColors.inkTertiary;
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
