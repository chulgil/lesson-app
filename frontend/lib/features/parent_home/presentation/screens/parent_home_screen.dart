import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../features/parent_home/domain/entities/user_profile.dart';
import '../../../../features/parent_home/presentation/providers/user_profile_provider.dart';
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
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _buildTabs(activeProfile),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.paperAccent,
          unselectedItemColor: AppColors.inkTertiary,
          items: _buildNavItems(activeProfile),
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
        const ParentPaymentsTab(), // Shows child's subscriptions / payments
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

  List<BottomNavigationBarItem> _buildNavItems(ProfileType activeProfile) {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: '홈',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: '레슨',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: '과제',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.credit_card_outlined),
        activeIcon: Icon(Icons.credit_card),
        label: '결제',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: '프로필',
      ),
    ];
  }
}
