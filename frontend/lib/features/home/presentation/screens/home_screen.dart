import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_bottom_nav.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../onboarding/onboarding_facade.dart';
import '../../../profile/profile_facade.dart' show questFirstShownProvider;
import '../../../profile/profile_ui_facade.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_ui_facade.dart';
import '../providers/home_lesson_summary_provider.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/home_quick_action_fab.dart';

/// Home screen (Teacher Dashboard)
// ignore: widget-smoke-test — existing screen, smoke test already covers HomeScreen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // UXC-3 (2026-08-20): Phase B 3-step 코치마크 시퀀스 제거.
    // `CoachMarkController.start()` 가 프로덕션 경로에서 한 번도 호출되지
    // 않아 컨트롤러·리스너·타깃 키가 전부 죽은 배선이었다. 시퀀스가 담고
    // 있던 "왜 필요한지" 카피는 QuestBoardCard 의 퀘스트 행 부제로 옮겼다
    // (사용자가 실제로 읽는 위치). core/widgets/coach_mark 라이브러리는
    // 향후 재사용을 위해 보존한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markQuestFirstShown();
    });
  }

  // §13 퀘스트 시스템 (2026-06-08): first-availability interstitial 제거.
  // 가입 흐름에서 first_availability_setup_screen 이 이미 슬롯 1개 필수 강제.
  // home 진입 시점에 추가 강제 안 함 — 퀘스트 카드 (선택) 로 안내.
  // Supersedes: docs/specs/onboarding/teacher_first_availability_setup.md §2 블로커 정책.

  /// 가입 직후 첫 도착 시점을 기록 (§13 Signup First Arrival).
  ///
  /// 이미 기록된 값이 있으면 무시 (덮어쓰기 X — 5분 윈도우 유지).
  /// QuestBoardCard 가 윈도우 내라면 자동 완료 카드를 2초 표시 후 소거.
  void _markQuestFirstShown() {
    final current = ref.read(questFirstShownProvider).value;
    if (current != null) return;
    // ignore: discarded_futures — fire-and-forget, 첫 도착 기록은 best-effort.
    ref.read(questFirstShownProvider.notifier).markShown();
  }

  @override
  Widget build(BuildContext context) {
    // §B3 Q6 (첫 학생 초대) 완료 직후 잠금 해제 축하 시트 1회 표시.
    // empty → non-empty 전이를 감지. Hive 영속화 (`questUnlockShown`) 로 1회 보장.
    ref.listen(homeStudentsProvider, (previous, next) {
      final prevEmpty = (previous?.valueOrNull?.isEmpty ?? true);
      final nextHas = (next.valueOrNull?.isNotEmpty ?? false);
      if (!prevEmpty || !nextHas) return;
      _maybeShowQuestUnlockSheet();
    });

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
        floatingActionButton: const HomeQuickActionFab(),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Future<void> _maybeShowQuestUnlockSheet() async {
    final storageAsync = ref.read(onboardingProgressStorageProvider);
    final storage = storageAsync.valueOrNull;
    if (storage == null) return;
    if (storage.questUnlockShown) return;
    if (!mounted) return;
    // 영속화 먼저 — 빌드 race 로 중복 호출돼도 1회만 표시.
    await ref
        .read(onboardingProgressStorageProvider.notifier)
        .markQuestUnlockShown();
    if (!mounted) return;
    await showQuestUnlockCelebrationSheet(context);
  }

  Widget _buildBottomNavigation() {
    return NotebookBottomNav(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        NotebookBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: AppStrings.homeTabLabel,
        ),
        NotebookBottomNavItem(
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month,
          label: AppStrings.scheduleTabTitle,
        ),
        NotebookBottomNavItem(
          icon: Icons.library_music_outlined,
          activeIcon: Icons.library_music,
          label: AppStrings.studentsTabLabel,
        ),
        NotebookBottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: AppStrings.profileTabLabel,
        ),
      ],
    );
  }
}
