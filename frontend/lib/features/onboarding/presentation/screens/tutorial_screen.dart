import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/auth_facade.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_onboarding.dart';
import '../../../../features/onboarding/onboarding_facade.dart';
import '../models/tutorial_step_content.dart';

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
      ref
          .read(teacherOnboardingNotifierProvider.notifier)
          .completeTutorialStep(step);
    }
    _navigateToHome();
  }

  void _navigateToHome() {
    ref.read(teacherOnboardingCompletedProvider.notifier).state = true;
    // Mark onboarding as completed on the server (remote mode)
    if (!ref.read(mockDataModeProvider)) {
      ref.read(authNotifierProvider.notifier).completeOnboarding();
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == TutorialStepContent.allSteps.length - 1;

    return NotebookScreenScaffold(
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
                        color: AppColors.inkTertiary,
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
                          side: BorderSide(color: AppColors.inkQuaternary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                        ),
                        child: Text(
                          '이전',
                          style: AppTypography.button.copyWith(
                            color: AppColors.inkSecondary,
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
                        backgroundColor: AppColors.paperAccent,
                        foregroundColor: AppColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
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
        _ProgressStep(
          step: 1,
          label: AppStrings.onboardingPhone,
          isActive: false,
          isCompleted: true,
        ),
        const SizedBox(width: AppSpacing.space1),
        _ProgressStep(
          step: 2,
          label: AppStrings.onboardingProfile,
          isActive: false,
          isCompleted: true,
        ),
        const SizedBox(width: AppSpacing.space1),
        _ProgressStep(
          step: 3,
          label: AppStrings.onboardingTutorial,
          isActive: true,
        ),
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
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              _getIconForStep(content.step),
              size: 80,
              color: AppColors.paperAccent,
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Notebook × Score: 튜토리얼 슬라이드 헤드라인 Playfair sectionTitle (§7.87-h).
          Text(
            content.title,
            style: NotebookTypography.sectionTitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Description
          Text(
            content.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
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
        color: isActive ? AppColors.paperAccent : AppColors.inkQuaternary,
        borderRadius: BorderRadius.zero,
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
            color:
                isActive || isCompleted
                    ? AppColors.paperAccent
                    : AppColors.inkQuaternary,
            borderRadius: BorderRadius.zero,
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, size: 12, color: AppColors.paper)
                    : Text(
                      '$step',
                      style: AppTypography.caption.copyWith(
                        color:
                            isActive ? AppColors.paper : AppColors.inkTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
