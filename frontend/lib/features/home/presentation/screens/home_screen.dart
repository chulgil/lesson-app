import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../schedule/presentation/screens/schedule_tab.dart';
import '../../../profile/presentation/screens/profile_tab.dart';
import '../../../students/presentation/screens/students_tab.dart';
import '../widgets/dashboard_tab.dart';

/// Home screen (Teacher Dashboard)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DebugWrapper(
      child: NotebookScreenScaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              DashboardTab(
                onViewAllLessons: () => setState(() => _currentIndex = 1),
              ),
              const ScheduleTab(),
              const StudentsTab(),
              const ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
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
              _buildNavItem(0, 'I', AppStrings.homeTabLabel),
              _buildNavItem(1, 'II', AppStrings.scheduleTabTitle),
              _buildNavItem(2, 'III', AppStrings.studentsTabLabel),
              _buildNavItem(3, 'IV', AppStrings.profileTabLabel),
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
        width: 72,
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
