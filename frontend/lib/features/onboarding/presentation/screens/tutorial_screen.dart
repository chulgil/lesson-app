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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _currentPage = 0;
  String? _selectedInstrument;
  bool _sampleStudentCreated = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (!_canContinue) return;
    if (_currentPage < TutorialStepContent.allSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  bool get _canContinue {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _selectedInstrument != null;
      case 1:
        return _sampleStudentCreated;
      case 2:
        return _noteController.text.trim().length >= 10;
      default:
        return false;
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
    ref.read(teacherOnboardingNotifierProvider.notifier).skipTutorial();
    await _navigateToHome();
  }

  Future<void> _completeTutorial() async {
    for (final step in TutorialStep.values) {
      ref
          .read(teacherOnboardingNotifierProvider.notifier)
          .completeTutorialStep(step);
    }
    await _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    ref.read(teacherOnboardingCompletedProvider.notifier).state = true;
    await ref
        .read(onboardingProgressStorageProvider.notifier)
        .markTeacherOnboardingCompleted();
    // Mark onboarding as completed on the server (remote mode)
    if (!ref.read(mockDataModeProvider)) {
      await ref.read(authNotifierProvider.notifier).completeOnboarding();
    }
    if (!mounted) return;
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
                      AppStrings.onboardingCategoryPreviewSkip,
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: TutorialStepContent.allSteps.length,
                itemBuilder: (context, index) {
                  final content = TutorialStepContent.allSteps[index];
                  return _TutorialPage(
                    content: content,
                    nameController: _nameController,
                    noteController: _noteController,
                    selectedInstrument: _selectedInstrument,
                    sampleStudentCreated: _sampleStudentCreated,
                    onInstrumentSelected:
                        (instrument) =>
                            setState(() => _selectedInstrument = instrument),
                    onSampleStudentCreated:
                        () => setState(() => _sampleStudentCreated = true),
                    onTextChanged: () => setState(() {}),
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
                          AppStrings.onboardingPrevious,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                      ),
                      onPressed: _canContinue ? _nextPage : null,
                      child: Text(
                        isLastPage ? AppStrings.onboardingCategoryPreviewStart : AppStrings.onboardingNext,
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
  final TextEditingController nameController;
  final TextEditingController noteController;
  final String? selectedInstrument;
  final bool sampleStudentCreated;
  final ValueChanged<String> onInstrumentSelected;
  final VoidCallback onSampleStudentCreated;
  final VoidCallback onTextChanged;

  const _TutorialPage({
    required this.content,
    required this.nameController,
    required this.noteController,
    required this.selectedInstrument,
    required this.sampleStudentCreated,
    required this.onInstrumentSelected,
    required this.onSampleStudentCreated,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space6),
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
                Icon(
                  _getIconForStep(content.step),
                  size: 42,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(content.title, style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  content.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                _buildInteractiveBody(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveBody(BuildContext context) {
    switch (content.step) {
      case TutorialStep.welcome:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const ValueKey('tutorial_name'),
              controller: nameController,
              onChanged: (_) => onTextChanged(),
              decoration: InputDecoration(
                labelText: AppStrings.tutorialTeacherNameLabel,
                hintText: AppStrings.tutorialTeacherNameHint,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children:
                  const ['피아노', '바이올린', '첼로', '보컬']
                      .map(
                        (instrument) => ChoiceChip(
                          label: Text(instrument),
                          selected: selectedInstrument == instrument,
                          onSelected: (_) => onInstrumentSelected(instrument),
                        ),
                      )
                      .toList(),
            ),
          ],
        );
      case TutorialStep.inviteStudent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                border: Border.all(color: AppColors.inkQuaternary),
              ),
              child: Text(
                sampleStudentCreated
                    ? '샘플 학생: 이서연 · $selectedInstrument'
                    : AppStrings.tutorialSampleStudentHint,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            OutlinedButton(
              onPressed: sampleStudentCreated ? null : onSampleStudentCreated,
              child: Text(sampleStudentCreated ? AppStrings.tutorialSampleStudentCreated : AppStrings.tutorialSampleStudentCreate),
            ),
          ],
        );
      case TutorialStep.writeFeedback:
        return TextField(
          key: const ValueKey('tutorial_note'),
          controller: noteController,
          onChanged: (_) => onTextChanged(),
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: AppStrings.lessonNotesTitle,
            hintText: AppStrings.tutorialLessonNoteHint,
          ),
        );
      case TutorialStep.createLesson:
      case TutorialStep.completed:
        return const SizedBox.shrink();
    }
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
