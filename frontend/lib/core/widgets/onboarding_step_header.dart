import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared onboarding step-progress header (#1104).
///
/// Renders a numbered step row (역할 → 분야 → 프로필 → 첫 가용시간) so the user
/// always sees "어디까지 왔는지". Reuses the visual pattern that lived locally in
/// `profile_setup_screen.dart` (`_ProgressStep` + `_ProgressDivider`) and follows
/// the notebook design language: square corners, AppColors/AppTypography/AppSpacing
/// tokens, no shadow.
///
/// This widget is discipline/role agnostic — it renders whatever [steps] and
/// [currentStep] it is given. Callers decide whether to show it (e.g. the shared
/// discipline-selection screen only mounts it for the teacher flow).
class OnboardingStepHeader extends StatelessWidget {
  /// SSOT for the teacher signup step labels, in order. [currentStep] is 1-based
  /// against this list.
  static const List<String> teacherSteps = [
    AppStrings.onboardingStepRole,
    AppStrings.onboardingStepDiscipline,
    AppStrings.onboardingStepProfile,
    AppStrings.onboardingStepAvailability,
  ];

  /// Ordered step labels. Length determines the number of steps rendered.
  final List<String> steps;

  /// The active step, 1-based against [steps].
  final int currentStep;

  const OnboardingStepHeader({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) {
        children.add(_ProgressDivider(isActive: i < currentStep));
      }
      children.add(
        _ProgressStep(
          step: i + 1,
          label: steps[i],
          isActive: i + 1 == currentStep,
        ),
      );
    }
    return Row(children: children);
  }
}

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;

  const _ProgressStep({
    required this.step,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
              borderRadius: BorderRadius.zero,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.bodySmall.copyWith(
                  color: isActive ? AppColors.paper : AppColors.inkTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.ink : AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressDivider extends StatelessWidget {
  final bool isActive;

  const _ProgressDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.space5),
      color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
    );
  }
}
