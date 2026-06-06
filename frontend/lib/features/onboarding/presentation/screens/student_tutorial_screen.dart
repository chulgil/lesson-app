import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../auth/auth_facade.dart';
import '../models/student_tutorial_step.dart';
import '../widgets/student_tutorial/feedback_step.dart';
import '../widgets/student_tutorial/metronome_step.dart';
import '../widgets/student_tutorial/recording_step.dart';
import '../widgets/student_tutorial/tuner_step.dart';

/// Tutorial screen for student onboarding with interactive steps.
class StudentTutorialScreen extends ConsumerStatefulWidget {
  const StudentTutorialScreen({super.key});

  @override
  ConsumerState<StudentTutorialScreen> createState() =>
      _StudentTutorialScreenState();
}

class _StudentTutorialScreenState extends ConsumerState<StudentTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _metronomeDone = false;
  bool _tunerDone = false;
  bool _recordingDone = false;
  bool _feedbackDone = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  bool get _canContinue {
    switch (_currentPage) {
      case 0:
        return _metronomeDone;
      case 1:
        return _tunerDone;
      case 2:
        return _recordingDone;
      case 3:
        return _feedbackDone;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (!_canContinue) return;
    if (_currentPage < StudentTutorialStepContent.all.length - 1) {
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

  Future<void> _skipTutorial() async {
    await _navigateToHome();
  }

  Future<void> _completeTutorial() async {
    await _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
    if (!ref.read(mockDataModeProvider)) {
      await ref.read(authNotifierProvider.notifier).completeOnboarding();
    }
    if (!mounted) return;
    context.go(AppRoutes.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage =
        _currentPage == StudentTutorialStepContent.all.length - 1;

    return NotebookScreenScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator and skip button
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

            // Page content with mission card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: StudentTutorialStepContent.all.length,
                itemBuilder: (context, index) {
                  final content = StudentTutorialStepContent.all[index];
                  return _StudentTutorialPage(
                    content: content,
                    metronomeDone: _metronomeDone,
                    tunerDone: _tunerDone,
                    recordingDone: _recordingDone,
                    feedbackDone: _feedbackDone,
                    onMetronomeDone:
                        () => setState(() => _metronomeDone = true),
                    onTunerDone: () => setState(() => _tunerDone = true),
                    onRecordingDone:
                        () => setState(() => _recordingDone = true),
                    onFeedbackDone: () => setState(() => _feedbackDone = true),
                  );
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  StudentTutorialStepContent.all.length,
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
                          shape: const RoundedRectangleBorder(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperAccent,
                        foregroundColor: AppColors.paper,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                      ),
                      onPressed: _canContinue ? _nextPage : null,
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
          label: AppStrings.onboardingProfile,
          isActive: false,
          isCompleted: true,
        ),
        const SizedBox(width: AppSpacing.space1),
        _ProgressStep(
          step: 2,
          label: AppStrings.onboardingTutorial,
          isActive: true,
        ),
      ],
    );
  }
}

class _StudentTutorialPage extends StatelessWidget {
  final StudentTutorialStepContent content;
  final bool metronomeDone;
  final bool tunerDone;
  final bool recordingDone;
  final bool feedbackDone;
  final VoidCallback onMetronomeDone;
  final VoidCallback onTunerDone;
  final VoidCallback onRecordingDone;
  final VoidCallback onFeedbackDone;

  const _StudentTutorialPage({
    required this.content,
    required this.metronomeDone,
    required this.tunerDone,
    required this.recordingDone,
    required this.feedbackDone,
    required this.onMetronomeDone,
    required this.onTunerDone,
    required this.onRecordingDone,
    required this.onFeedbackDone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space6),
          // Mission card with border
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space5),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Icon(
                  _getIconForStep(content.step),
                  size: 42,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(height: AppSpacing.space4),

                // Title
                Text(content.title, style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space2),

                // Description
                Text(
                  content.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),

                // Step widget body
                _buildStepWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWidget() {
    switch (content.step) {
      case StudentTutorialStep.metronome:
        return MetronomeStep(
          completed: metronomeDone,
          onComplete: onMetronomeDone,
        );
      case StudentTutorialStep.tuner:
        return TunerStep(completed: tunerDone, onComplete: onTunerDone);
      case StudentTutorialStep.recording:
        return RecordingStep(
          completed: recordingDone,
          onComplete: onRecordingDone,
        );
      case StudentTutorialStep.feedback:
        return FeedbackStep(
          completed: feedbackDone,
          onComplete: onFeedbackDone,
        );
    }
  }

  IconData _getIconForStep(StudentTutorialStep step) {
    switch (step) {
      case StudentTutorialStep.metronome:
        return Icons.av_timer_rounded;
      case StudentTutorialStep.tuner:
        return Icons.graphic_eq_rounded;
      case StudentTutorialStep.recording:
        return Icons.fiber_manual_record_rounded;
      case StudentTutorialStep.feedback:
        return Icons.edit_note_rounded;
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
