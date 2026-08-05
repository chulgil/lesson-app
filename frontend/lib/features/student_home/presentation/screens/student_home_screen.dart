import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/center_action_slot.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_bottom_nav.dart';
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
              parts.add(
                AppStrings.studentHomeRecordingRecoveredCount(result.recovered),
              );
            }
            if (result.cleanedUp > 0) {
              parts.add(
                AppStrings.studentHomeRecordingCleanedCount(result.cleanedUp),
              );
            }
            message = AppStrings.studentHomeRecordingRecoverySummary(
              parts.join(', '),
              result.total,
            );
            bgColor = AppColors.paperOk;
          } else {
            message = AppStrings.studentHomeRecordingVerified(result.total);
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
    return NotebookBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      // Center practice button via discipline-neutral slot (#975).
      // Music injects the action; null slots stay unwrapped (see
      // CenterActionSlot doc) so non-music shells do not shift.
      centerAction: const CenterActionSlot(
        centerAction: PracticeCenterButton(size: 48),
      ),
      items: const [
        NotebookBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: AppStrings.navHome,
        ),
        NotebookBottomNavItem(
          icon: Icons.event_note_outlined,
          activeIcon: Icons.event_note,
          label: AppStrings.navLessons,
        ),
        NotebookBottomNavItem(
          icon: Icons.music_note_outlined,
          activeIcon: Icons.music_note,
          label: AppStrings.navPractice,
        ),
        NotebookBottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: AppStrings.navProfile,
        ),
      ],
    );
  }
}
