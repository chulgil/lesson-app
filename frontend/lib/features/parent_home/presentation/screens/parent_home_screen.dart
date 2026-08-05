import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_bottom_nav.dart';
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
    return NotebookBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
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
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          label: AppStrings.navAssignments,
        ),
        NotebookBottomNavItem(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet,
          label: AppStrings.navPayments,
        ),
        NotebookBottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: AppStrings.navProfile,
        ),
      ],
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
