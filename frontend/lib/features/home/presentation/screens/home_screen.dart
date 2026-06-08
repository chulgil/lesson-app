import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/coach_mark/coach_mark_controller.dart';
import '../../../../core/widgets/coach_mark/coach_mark_overlay.dart';
import '../../../../core/widgets/coach_mark/coach_mark_scope.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../onboarding/onboarding_facade.dart';
import '../../../profile/presentation/providers/quest_first_shown_provider.dart';
import '../../../profile/profile_ui_facade.dart';
import '../../../settings/settings_facade.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_ui_facade.dart';
import '../providers/teacher_profile_completion_provider.dart';
import '../widgets/dashboard_tab.dart';

/// Home screen (Teacher Dashboard)
// ignore: widget-smoke-test — existing screen, smoke test already covers HomeScreen
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _settingsNavKey = GlobalKey();
  final _studentsNavKey = GlobalKey();

  late final CoachMarkController _coachMarkController;

  bool _wasCoachMarkActive = false;

  @override
  void initState() {
    super.initState();
    // Coach mark: only guide to lesson time settings on first entry.
    // Student invite requires phone verification + full setup first,
    // so it's handled via QuestBoard, not coach mark.
    _coachMarkController = CoachMarkController(
      steps: [
        CoachMarkStep(
          id: 'lesson_time_settings',
          targetKey: _settingsNavKey,
          title: AppStrings.coachMarkTimeTitle,
          description: AppStrings.coachMarkTimeDescription,
          actionLabel: AppStrings.coachMarkTimeAction,
          position: CoachMarkPosition.above,
          onAction: () => setState(() => _currentIndex = 3),
        ),
      ],
    );

    _coachMarkController.addListener(_onCoachMarkChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeStartCoachMark();
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

  void _onCoachMarkChanged() {
    if (_wasCoachMarkActive && !_coachMarkController.isActive) {
      ref
          .read(onboardingProgressStorageProvider.notifier)
          .markCoachMarkCompleted();
    }
    _wasCoachMarkActive = _coachMarkController.isActive;
  }

  // Subscription used to wait for the onboarding-progress storage (Hive) to
  // finish loading before deciding whether to start the coach mark. On the
  // first frame the provider is still AsyncLoading, so valueOrNull is null and
  // a single sync read would skip the coach mark entirely. (#7)
  ProviderSubscription<AsyncValue<OnboardingProgressStorageState>>?
  _coachMarkLoadSub;

  void _maybeStartCoachMark() {
    final storageAsync = ref.read(onboardingProgressStorageProvider);
    if (!storageAsync.hasValue) {
      // Storage not loaded yet — re-check once a value arrives, then clean up.
      _coachMarkLoadSub?.close();
      _coachMarkLoadSub = ref.listenManual(onboardingProgressStorageProvider, (
        previous,
        next,
      ) {
        if (next.hasValue && mounted) {
          _coachMarkLoadSub?.close();
          _coachMarkLoadSub = null;
          _maybeStartCoachMark();
        }
      });
      return;
    }
    final storage = storageAsync.valueOrNull;
    if (storage == null || storage.coachMarkCompleted) return;

    // The blocking first-availability interstitial is the single source of
    // "set lesson time" guidance. The lesson-time coach mark duplicated it and
    // re-prompted "레슨 시간을 설정하세요" even after the teacher had already set
    // it (the interstitial sets slots, then the rebuilt home re-ran this and
    // started the coach mark). Once slots exist the action is done → mark the
    // coach mark complete; before slots exist the interstitial handles it, so
    // we never auto-start the coach mark.
    final settingsAsync = ref.read(teacherSettingsProvider);
    if (settingsAsync.hasValue && ref.read(hasAvailableSlotsProvider)) {
      ref
          .read(onboardingProgressStorageProvider.notifier)
          .markCoachMarkCompleted();
    }
  }

  @override
  void dispose() {
    _coachMarkLoadSub?.close();
    _coachMarkController.removeListener(_onCoachMarkChanged);
    _coachMarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DebugWrapper(
      child: NotebookScreenScaffold(
        body: SafeArea(
          child: CoachMarkScope(
            controller: _coachMarkController,
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
              _buildNavItem(
                2,
                'III',
                AppStrings.studentsTabLabel,
                key: _studentsNavKey,
              ),
              _buildNavItem(
                3,
                'IV',
                AppStrings.profileTabLabel,
                key: _settingsNavKey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String roman, String label, {Key? key}) {
    final isSelected = _currentIndex == index;
    final accentColor =
        isSelected ? AppColors.paperAccent : AppColors.inkTertiary;

    return InkWell(
      key: key,
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
