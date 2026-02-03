import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../main.dart' show getStartupRecoveryResult, clearStartupRecoveryResult;
import '../../../../core/widgets/practice_center_button.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
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
      ref.read(currentUserRoleProvider.notifier).state = UserRole.student;
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
            bgColor = AppColors.success;
          } else {
            message = '녹음 파일 ${result.total}개 확인됨 (복구 불필요)';
            bgColor = AppColors.info;
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
    return DebugWrapper(
      child: Scaffold(
        body: SafeArea(
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
        bottomNavigationBar: _buildBottomNavigationWithCenterButton(),
      ),
    );
  }

  Widget _buildBottomNavigationWithCenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, '홈'),
              _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, '스케줄'),
              // Center practice button (same level as other items)
              const PracticeCenterButton(size: 48),
              _buildNavItem(
                  2, Icons.fitness_center_outlined, Icons.fitness_center, '연습'),
              _buildNavItem(3, Icons.person_outline, Icons.person, '프로필'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? AppColors.primary : AppColors.textTertiaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
