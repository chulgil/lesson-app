import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Visual progress bar showing session completion status.
///
/// Displays up to 8 indicators per row with optional [전체] button.
/// Each indicator shows completion state: completed, selected, or future.
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

  static const double _indicatorSize = 32;
  static const int _maxPerRow = 8;

  @override
  Widget build(BuildContext context) {
    final indicators = List.generate(
      totalSessions,
      (index) => index + 1,
    );

    final rows = _buildRows(indicators);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space2),
          rows[i],
        ],
      ],
    );
  }

  List<Widget> _buildRows(List<int> sessionNumbers) {
    final rows = <Widget>[];
    final firstRowCount =
        isMonthly ? _maxPerRow - 1 : _maxPerRow;
    final firstRowSessions = sessionNumbers.take(firstRowCount).toList();
    final remaining = sessionNumbers.skip(firstRowCount).toList();

    rows.add(_buildRow(firstRowSessions, showBulkButton: isMonthly));

    for (int i = 0; i < remaining.length; i += _maxPerRow) {
      final end =
          (i + _maxPerRow < remaining.length) ? i + _maxPerRow : remaining.length;
      rows.add(_buildRow(remaining.sublist(i, end)));
    }

    return rows;
  }

  Widget _buildRow(
    List<int> sessions, {
    bool showBulkButton = false,
  }) {
    return Row(
      children: [
        for (int i = 0; i < sessions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space2),
          _SessionIndicator(
            sessionNumber: sessions[i],
            state: _getSessionState(sessions[i]),
            isSelected: sessions[i] == selectedSession,
            hasChangeRequest: changeRequestedSessions.contains(sessions[i]),
            onTap: () => onSessionTap(sessions[i]),
          ),
        ],
        if (showBulkButton) ...[
          const SizedBox(width: AppSpacing.space2),
          _BulkChangeButton(onTap: onBulkChangeTap),
        ],
      ],
    );
  }

  _SessionState _getSessionState(int sessionNumber) {
    if (sessionNumber <= completedSessions) {
      return _SessionState.completed;
    }
    if (sessionNumber == selectedSession) {
      return _SessionState.scheduled;
    }
    return _SessionState.future;
  }
}

enum _SessionState { completed, scheduled, future }

class _SessionIndicator extends StatelessWidget {
  final int sessionNumber;
  final _SessionState state;
  final bool isSelected;
  final bool hasChangeRequest;
  final VoidCallback onTap;

  const _SessionIndicator({
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
        width: SessionProgressBar._indicatorSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircle(),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '$sessionNumber',
              style: AppTypography.caption.copyWith(
                color: _numberColor,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: SessionProgressBar._indicatorSize,
          height: SessionProgressBar._indicatorSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _fillColor,
            border: Border.all(
              color: _borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Center(child: _buildContent()),
        ),
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

  Widget _buildContent() {
    switch (state) {
      case _SessionState.completed:
        return const Icon(
          Icons.check,
          size: AppSpacing.iconXS,
          color: Colors.white,
        );
      case _SessionState.scheduled:
        return const Icon(
          Icons.calendar_today,
          size: AppSpacing.iconXS - 2,
          color: Colors.white,
        );
      case _SessionState.future:
        return Text(
          '$sessionNumber',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Color get _fillColor {
    switch (state) {
      case _SessionState.completed:
        return AppColors.success;
      case _SessionState.scheduled:
        return AppColors.primary;
      case _SessionState.future:
        return Colors.transparent;
    }
  }

  Color get _borderColor {
    if (isSelected) return AppColors.primary;
    switch (state) {
      case _SessionState.completed:
        return AppColors.success;
      case _SessionState.scheduled:
        return AppColors.primary;
      case _SessionState.future:
        return AppColors.textTertiaryLight;
    }
  }

  Color get _numberColor {
    if (isSelected) return AppColors.primary;
    switch (state) {
      case _SessionState.completed:
        return AppColors.success;
      case _SessionState.scheduled:
        return AppColors.primary;
      case _SessionState.future:
        return AppColors.textTertiaryLight;
    }
  }
}

class _BulkChangeButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _BulkChangeButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: SessionProgressBar._indicatorSize,
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
