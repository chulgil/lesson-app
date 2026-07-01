import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/auth/auth_facade.dart' show activeDisciplineProvider;
import '../../../../features/practice/practice_facade.dart'
    show metronomeProvider;
import '../providers/tuner_provider.dart';
import 'practice_tools/music_practice_tools.dart';
import 'practice_tools/practice_tool.dart';
import 'practice_tools/practice_tool_registry.dart';

/// Practice tools modal with tab-based navigation between Metronome and Tuner.
class PracticeToolsModal extends ConsumerStatefulWidget {
  const PracticeToolsModal({
    super.key,
    this.initialTab = 0,
    this.studentId,
    this.tools,
  });

  /// Initial tab index (0 = Metronome, 1 = Tuner)
  final int initialTab;

  /// 학생 컨텍스트. null 이면 메트로놈 stop 시 [PracticeSourceLoggers] 트리거 안 함.
  /// 학생 게이미피케이션 P1 — Job 7 라우팅 진입점에서 주입.
  final String? studentId;

  /// Injectable practice-tool set. Defaults to [musicPracticeTools] (Phase 3 =
  /// music only). A Phase 4 (#979) discipline-keyed registry resolves this; the
  /// [show] entry point keeps its byte-identical signature, so callers never
  /// pass it today.
  final List<PracticeTool>? tools;

  /// 메트로놈 stop 시 [studentId] 가 주어졌고 측정된 분이 1 이상이면
  /// modal 이 자동으로 닫히면서 그 분 수를 반환한다. 그 외 경우 (튜너 사용,
  /// 0분 stop, 사용자 수동 닫기) 는 `null` 반환.
  static Future<int?> show(
    BuildContext context, {
    int initialTab = 0,
    String? studentId,
  }) {
    return showNotebookModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) =>
              PracticeToolsModal(initialTab: initialTab, studentId: studentId),
    );
  }

  @override
  ConsumerState<PracticeToolsModal> createState() => _PracticeToolsModalState();
}

class _PracticeToolsModalState extends ConsumerState<PracticeToolsModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final List<PracticeTool> _tools;

  /// Index of the tuner tool within [_tools], or -1 if this discipline has no
  /// tuner. The microphone lifecycle handlers gate on this so a discipline
  /// without a tuner (Phase 4 / #979-B: fitness) never touches [tunerProvider].
  late final int _tunerIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Resolve this session's practice tools from the active discipline (#979-A).
    // Music is the only registered discipline and its fallback, so this stays a
    // byte-identical [musicPracticeTools] today. The active discipline is read
    // only when no explicit [tools] are injected.
    _tools =
        widget.tools ??
        PracticeToolRegistry.forDiscipline(
          ref.read(activeDisciplineProvider).id,
        );
    _tunerIndex = _tools.indexWhere((tool) => tool.id == PracticeToolIds.tuner);

    _tabController = TabController(
      length: _tools.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Listen for tab changes to manage tuner microphone
    _tabController.addListener(_onTabChanged);

    // Pre-warm metronome and tuner only when tuner tab is opened.
    // Tuner should keep microphone inactive unless user enters tuner mode.
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();

      if (_tunerIndex >= 0 && widget.initialTab == _tunerIndex) {
        unawaited(_activateTunerProcessing());
      }
    });
  }

  @override
  void deactivate() {
    // Stop tuner completely when modal closes (including stream).
    // dispose 가 아닌 deactivate 에 두는 이유: riverpod 3.x 환경에서
    // ConsumerStatefulElement.dispose 가 호출되는 시점에는 ref 가 이미 무효 —
    // 위젯이 element tree 에서 제거되는 deactivate 시점에는 아직 유효.
    if (_tunerIndex >= 0) {
      ref.read(tunerProvider.notifier).stopCompletely();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // NOTE (#979-A): the tuner microphone lifecycle handlers below are specific to
  // the tuner tool. They gate on [_tunerIndex] (the tuner's position within
  // [_tools], or -1 if absent), so a discipline without a tuner never touches
  // [tunerProvider]. For the music discipline the tuner is index 1, so behaviour
  // is byte-identical to the previous hardcoded `== 1` checks.
  /// Handle tab changes - toggle tuner processing (instant, no blocking)
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tunerIndex < 0) return;

    final tuner = ref.read(tunerProvider.notifier);
    if (_tabController.index == _tunerIndex) {
      // Switching TO tuner tab - warm and enable processing.
      unawaited(_activateTunerProcessing());
    } else {
      // Switching AWAY from tuner tab - clear tuner processing state.
      tuner.disableProcessing();
    }
  }

  Future<void> _activateTunerProcessing() async {
    if (!mounted || _tunerIndex < 0) return;
    final tuner = ref.read(tunerProvider.notifier);
    await tuner.warmUp();
    if (!mounted || _tabController.index != _tunerIndex) return;
    await tuner.enableProcessing();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_tunerIndex < 0) return;
    final tuner = ref.read(tunerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - stop tuner (not recording)
        tuner.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        if (_tabController.index == _tunerIndex) {
          // On tuner tab - full resume (permission check + stream restart + enable)
          tuner.onAppResumed();
        } else {
          // On other tab - keep tuner closed while inactive.
          tuner.stopCompletely();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Handle bar
          const BottomSheetHandle(
            margin: EdgeInsets.only(top: AppSpacing.space2),
          ),

          // Header with tabs
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.paperAccent,
                    unselectedLabelColor: AppColors.inkSecondary,
                    indicatorColor: AppColors.paperAccent,
                    indicatorWeight: 3,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: AppTypography.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: [
                      for (final tool in _tools) Tab(text: tool.displayLabel),
                    ],
                  ),
                ),
                // Settings button for tuner
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    final onShowSettings =
                        _tools[_tabController.index].onShowSettings;
                    return onShowSettings != null
                        ? IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => onShowSettings(context),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        )
                        : const SizedBox(width: AppSpacing.space10);
                  },
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final tool in _tools)
                  tool.panelBuilder(context, widget.studentId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
