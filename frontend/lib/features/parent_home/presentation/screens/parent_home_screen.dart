import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../features/parent_home/domain/entities/user_profile.dart';
import '../../../../features/parent_home/parent_home_facade.dart';
import 'parent_dashboard_tab.dart';
import 'parent_lessons_tab.dart';
import 'parent_assignments_tab.dart';
import 'parent_payments_tab.dart';
import 'parent_profile_tab.dart';
import 'unconnected_child_dashboard.dart';

/// Parent home screen with profile-aware navigation
///
/// Shows different screens based on active profile:
/// - Parent mode: Full parent dashboard with tabs
/// - Student mode: Redirects to student home (handled by router)
/// - Child mode (connected): Child-specific view with lessons
/// - Child mode (unconnected): Simplified practice-only dashboard
class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isUnconnectedChild = ref.watch(isUnconnectedChildModeProvider);
    final activeProfile = ref.watch(activeProfileTypeProvider);

    // Show unconnected child dashboard if in child mode with unconnected child
    if (isUnconnectedChild) {
      return const UnconnectedChildDashboard();
    }

    // For connected child, show limited parent view (no lessons/assignments editing)
    // For parent mode, show full parent view
    return DebugWrapper(
      child: NotebookScreenScaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _buildTabs(activeProfile),
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
              _buildNavItem(0, 'I', '홈'),
              _buildNavItem(1, 'II', '레슨'),
              _buildNavItem(2, 'III', '과제'),
              _buildNavItem(3, 'IV', '입금'),
              _buildNavItem(4, 'V', '프로필'),
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
        width: 60,
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

  List<Widget> _buildTabs(ProfileType activeProfile) {
    // For child mode (connected), show child-specific tabs
    if (activeProfile == ProfileType.child) {
      return [
        const ParentDashboardTab(), // Shows child's practice overview
        const ParentLessonsTab(), // Shows child's upcoming lessons
        const ParentAssignmentsTab(), // Shows child's assignments
        const ParentPaymentsTab(), // Shows child's subscriptions / deposit status
        const ParentProfileTab(),
      ];
    }

    // Parent mode - full access
    return [
      const ParentDashboardTab(),
      const ParentLessonsTab(),
      const ParentAssignmentsTab(),
      const ParentPaymentsTab(),
      const ParentProfileTab(),
    ];
  }
}
