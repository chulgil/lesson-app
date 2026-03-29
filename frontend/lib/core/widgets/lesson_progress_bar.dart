import 'package:flutter/material.dart';

import '../../features/schedule/domain/entities/unified_lesson_request.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 5-phase progress bar for the lesson lifecycle chapter model.
///
/// Displays: 신청 → 확정 → 결제 → 진행 → 완료
/// Active/completed phases show primary color, future phases show muted.
class LessonProgressBar extends StatelessWidget {
  final RequestPhase currentPhase;

  const LessonProgressBar({
    super.key,
    required this.currentPhase,
  });

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
              child: Container(
                height: 2,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.borderLight,
              ),
            );
          }

          // Phase dot + label
          final phaseIndex = index ~/ 2;
          final phase = phases[phaseIndex];
          final state = _phaseState(phaseIndex);

          return _PhaseDot(
            label: phase.label,
            state: state,
          );
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

class _PhaseDot extends StatelessWidget {
  final String label;
  final _PhaseState state;

  const _PhaseDot({
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color textColor;
    final double dotSize;

    switch (state) {
      case _PhaseState.completed:
        dotColor = AppColors.primary;
        textColor = AppColors.primary;
        dotSize = 8;
      case _PhaseState.active:
        dotColor = AppColors.primary;
        textColor = AppColors.primary;
        dotSize = 12;
      case _PhaseState.future:
        dotColor = AppColors.borderLight;
        textColor = AppColors.textTertiaryLight;
        dotSize = 8;
      case _PhaseState.muted:
        dotColor = AppColors.scheduleMutedAccent;
        textColor = AppColors.textTertiaryLight;
        dotSize = 8;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: textColor,
            fontWeight: state == _PhaseState.active
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
