import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/coach_mark/coach_mark_controller.dart';
import '../../../../core/widgets/coach_mark/coach_mark_overlay.dart';
import '../../../../core/widgets/coach_mark/coach_mark_scope.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../onboarding/onboarding_facade.dart';
import '../../../onboarding/presentation/widgets/quest_unlock_celebration_sheet.dart';
import '../../../profile/presentation/providers/quest_first_shown_provider.dart';
import '../../../profile/profile_ui_facade.dart';
import '../../../settings/settings_facade.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_ui_facade.dart';
import '../providers/home_lesson_summary_provider.dart';
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
  // Phase B step 3 target — 레슨 탭 (감사 §4.4 B2).
  final _scheduleNavKey = GlobalKey();

  late final CoachMarkController _coachMarkController;

  bool _wasCoachMarkActive = false;

  @override
  void initState() {
    super.initState();
    // Phase B 3-step 코치마크 시퀀스 (감사 §4.4 B2) —
    // SSOT: docs/specs/onboarding/teacher_onboarding_v3_spec.md §3.3.
    //   1) lesson_time_settings → 설정 탭 → 가용시간 등록
    //   2) first_student_invite → 학생 탭 → 첫 학생 초대
    //   3) first_lesson_register → 레슨 탭 → 첫 레슨 등록
    // 시퀀스 종료 후 QuestBoardCard 가 다음 진입점을 안내한다.
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
        CoachMarkStep(
          id: 'first_student_invite',
          targetKey: _studentsNavKey,
          title: AppStrings.coachMarkFirstStudentInviteTitle,
          description: AppStrings.coachMarkFirstStudentInviteDescription,
          actionLabel: AppStrings.coachMarkFirstStudentInviteAction,
          position: CoachMarkPosition.above,
          onAction: () {
            setState(() => _currentIndex = 2);
            // Deep wiring (#652): 학생 탭 전환 후 초대 화면까지 안내.
            context.push(AppRoutes.invite);
          },
        ),
        CoachMarkStep(
          id: 'first_lesson_register',
          targetKey: _scheduleNavKey,
          title: AppStrings.coachMarkFirstLessonRegisterTitle,
          description: AppStrings.coachMarkFirstLessonRegisterDescription,
          actionLabel: AppStrings.coachMarkFirstLessonRegisterAction,
          position: CoachMarkPosition.above,
          onAction: () {
            setState(() => _currentIndex = 1);
            // Deep wiring (#652): 레슨 탭 전환 후 레슨 추가 화면까지 안내.
            context.push(AppRoutes.addLesson);
          },
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
              _buildNavItem(
                1,
                'II',
                AppStrings.scheduleTabTitle,
                key: _scheduleNavKey,
              ),
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
    final accentColor = isSelected
        ? AppColors.paperAccent
        : AppColors.inkTertiary;

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
