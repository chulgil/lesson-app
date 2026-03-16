import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/auth/user_role_provider.dart';

/// Tutorial screen for student onboarding
class StudentTutorialScreen extends ConsumerStatefulWidget {
  const StudentTutorialScreen({super.key});

  @override
  ConsumerState<StudentTutorialScreen> createState() =>
      _StudentTutorialScreenState();
}

class _StudentTutorialScreenState
    extends ConsumerState<StudentTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _StudentTutorialPageData(
      icon: Icons.waving_hand_rounded,
      title: '환영합니다!',
      description: '레슨 앱에서 선생님과 함께\n음악 여정을 시작해보세요',
    ),
    _StudentTutorialPageData(
      icon: Icons.calendar_month_rounded,
      title: '레슨 확인',
      description: '선생님과의 레슨 일정을\n한눈에 확인하고 관리할 수 있어요',
    ),
    _StudentTutorialPageData(
      icon: Icons.fitness_center_outlined,
      title: '연습 기록',
      description: '매일 연습을 기록하고\n나의 성장을 확인해보세요',
    ),
    _StudentTutorialPageData(
      icon: Icons.people_rounded,
      title: '선생님과 소통',
      description: '선생님의 피드백을 확인하고\n더 나은 연습을 해보세요',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
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
    _navigateToHome();
  }

  void _completeTutorial() {
    _navigateToHome();
  }

  void _navigateToHome() {
    ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
    if (!EnvironmentConfig.useMockData) {
      ref.read(authNotifierProvider.notifier).completeOnboarding();
    }
    context.go(AppRoutes.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _StudentTutorialPage(data: page);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
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
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusLarge),
                          ),
                          minimumSize:
                              const Size(0, AppSpacing.buttonHeight),
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLarge),
                        ),
                        minimumSize:
                            const Size(0, AppSpacing.buttonHeight),
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
}

class _StudentTutorialPageData {
  final IconData icon;
  final String title;
  final String description;

  const _StudentTutorialPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _StudentTutorialPage extends StatelessWidget {
  final _StudentTutorialPageData data;

  const _StudentTutorialPage({required this.data});

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
              data.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Title
          Text(
            data.title,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space3),

          // Description
          Text(
            data.description,
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
