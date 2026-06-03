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
import '../../../onboarding/presentation/providers/onboarding_progress_storage_provider.dart';
import '../../../onboarding/presentation/widgets/first_availability_interstitial.dart';
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
      _maybeShowFirstAvailabilityInterstitial();
      _maybeStartCoachMark();
    });
  }

  bool _interstitialShown = false;

  /// Show the first-availability interstitial when the teacher lands on
  /// the home screen without any active availability slot (#422).
  /// The dialog itself blocks back-navigation and dismiss, so we only
  /// trigger it once per session — the slot count flips immediately
  /// after the teacher saves a slot, so it will not reopen.
  ///
  /// Only decide after settings have finished loading: [hasAvailableSlots]
  /// derives from [teacherSettingsProvider] and reports `false` while still
  /// loading, which would otherwise flash the interstitial at teachers who
  /// already have slots. (#5 D-G3 — settings/profile SSOT)
  void _maybeShowFirstAvailabilityInterstitial() {
    if (_interstitialShown) return;
    final settingsAsync = ref.read(teacherSettingsProvider);
    if (!settingsAsync.hasValue) {
      // Settings not loaded yet — re-check once a value arrives.
      ref.listenManual(teacherSettingsProvider, (previous, next) {
        if (next.hasValue && mounted) {
          _maybeShowFirstAvailabilityInterstitial();
        }
      });
      return;
    }
    final hasSlots = ref.read(hasAvailableSlotsProvider);
    if (hasSlots) return;
    _interstitialShown = true;
    showFirstAvailabilityInterstitial(context);
  }

  void _onCoachMarkChanged() {
    if (_wasCoachMarkActive && !_coachMarkController.isActive) {
      ref
          .read(onboardingProgressStorageProvider.notifier)
          .markCoachMarkCompleted();
    }
    _wasCoachMarkActive = _coachMarkController.isActive;
  }

  void _maybeStartCoachMark() {
    final storage = ref.read(onboardingProgressStorageProvider).valueOrNull;
    if (storage != null && !storage.coachMarkCompleted) {
      _coachMarkController.start();
    }
  }

  @override
  void dispose() {
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
