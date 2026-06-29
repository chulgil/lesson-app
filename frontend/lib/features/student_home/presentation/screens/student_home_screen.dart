import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../main.dart'
    show getStartupRecoveryResult, clearStartupRecoveryResult;
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../../core/widgets/practice_center_button.dart';
import '../providers/student_home_session_provider.dart';
import '../providers/student_home_tab_request_provider.dart';
import 'student_dashboard_tab.dart';
import 'student_lessons_tab.dart';
import 'student_practice_tab.dart';
import 'student_profile_tab.dart';

/// Student home screen with practice dashboard
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-switch to student role when entering this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentHomeSessionActionsProvider).setStudentRole();
    });
    // Show recording recovery message if any recordings were recovered at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = getStartupRecoveryResult();
      if (result != null && mounted) {
        // Always show diagnostic message if there are recordings in DB
        if (result.total > 0) {
          String message;
          Color bgColor;

          if (result.recovered > 0 || result.cleanedUp > 0) {
            final parts = <String>[];
            if (result.recovered > 0) {
              parts.add('${result.recovered}개 복구');
            }
            if (result.cleanedUp > 0) {
              parts.add('${result.cleanedUp}개 정리');
            }
            message = '녹음 파일: ${parts.join(', ')} (전체 ${result.total}개)';
            bgColor = AppColors.paperOk;
          } else {
            message = '녹음 파일 ${result.total}개 확인됨 (복구 불필요)';
            bgColor = AppColors.ink;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 4),
              backgroundColor: bgColor,
            ),
          );
        }
        clearStartupRecoveryResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // #749: descendant widgets request a tab switch (e.g. trial "더보기" →
    // Lessons) via studentHomeTabRequestProvider; consume and reset it here.
    ref.listen<int?>(studentHomeTabRequestProvider, (_, next) {
      if (next != null) {
        setState(() => _currentIndex = next);
        ref.read(studentHomeTabRequestProvider.notifier).state = null;
      }
    });
    return DebugWrapper(
      child: NotebookScreenScaffold(
        body: SafeArea(
          child: PaperScaffold(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                StudentDashboardTab(),
                StudentLessonsTab(),
                StudentPracticeTab(),
                StudentProfileTab(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationWithCenterButton(),
      ),
    );
  }

  Widget _buildBottomNavigationWithCenterButton() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'I', AppStrings.navHome),
              _buildNavItem(1, 'II', AppStrings.navLessons),
              // Center practice button (same level as other items)
              const PracticeCenterButton(size: 48),
              _buildNavItem(2, 'III', AppStrings.navPractice),
              _buildNavItem(3, 'IV', AppStrings.navProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String roman, String label) {
    final isSelected = _currentIndex == index;
    final accentColor =
        isSelected ? AppColors.paperAccent : AppColors.inkTertiary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              roman,
              style: NotebookTypography.roman.copyWith(
                fontSize: 18,
                color: accentColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: NotebookTypography.sectionLabel.copyWith(
                fontSize: 10,
                color: accentColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
