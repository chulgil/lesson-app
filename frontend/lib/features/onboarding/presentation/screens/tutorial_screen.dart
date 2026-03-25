import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_onboarding.dart';
import '../../../../providers/onboarding/onboarding_providers.dart';

/// Tutorial screen for teacher onboarding
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < TutorialStepContent.allSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipTutorial() {
    ref.read(teacherOnboardingNotifierProvider.notifier).skipTutorial();
    _navigateToHome();
  }

  void _completeTutorial() {
    for (final step in TutorialStep.values) {
      ref.read(teacherOnboardingNotifierProvider.notifier).completeTutorialStep(step);
    }
    _navigateToHome();
  }

  void _navigateToHome() {
    ref.read(teacherOnboardingCompletedProvider.notifier).state = true;
    // Mark onboarding as completed on the server (remote mode)
    if (!EnvironmentConfig.useMockData) {
      ref.read(authNotifierProvider.notifier).completeOnboarding();
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == TutorialStepContent.allSteps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),

                  // Skip button
                  TextButton(
                    onPressed: _skipTutorial,
                    child: Text(
                      '건너뛰기',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: TutorialStepContent.allSteps.length,
                itemBuilder: (context, index) {
                  final content = TutorialStepContent.allSteps[index];
                  return _TutorialPage(content: content);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  TutorialStepContent.allSteps.length,
                  (index) => _PageIndicator(isActive: index == _currentPage),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  // Back button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                          ),
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                        ),
                        child: Text(
                          '이전',
                          style: AppTypography.button.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),

                  if (_currentPage > 0)
                    const SizedBox(width: AppSpacing.space3),

                  // Next/Complete button
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        ),
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                      ),
                      child: Text(
                        isLastPage ? '시작하기' : '다음',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressStep(step: 1, label: '휴대폰', isActive: false, isCompleted: true),
        const SizedBox(width: AppSpacing.space1),
        _ProgressStep(step: 2, label: '프로필', isActive: false, isCompleted: true),
        const SizedBox(width: AppSpacing.space1),
        _ProgressStep(step: 3, label: '튜토리얼', isActive: true),
      ],
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final TutorialStepContent content;

  const _TutorialPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForStep(content.step),
              size: 80,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Title
          Text(
            content.title,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Description
          Text(
            content.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForStep(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return Icons.waving_hand_rounded;
      case TutorialStep.inviteStudent:
        return Icons.qr_code_rounded;
      case TutorialStep.createLesson:
        return Icons.calendar_month_rounded;
      case TutorialStep.writeFeedback:
        return Icons.edit_note_rounded;
      case TutorialStep.completed:
        return Icons.celebration_rounded;
    }
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.borderLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _ProgressStep({
    required this.step,
    required this.label,
    required this.isActive,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.borderLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '$step',
                    style: AppTypography.caption.copyWith(
                      color: isActive
                          ? Colors.white
                          : AppColors.textTertiaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
