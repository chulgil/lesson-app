import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/practice/practice_facade.dart'
    show metronomeProvider;
import '../providers/tuner_provider.dart';
import 'practice_tools/metronome_panel.dart';
import 'practice_tools/tuner_panel.dart';
import 'tuner/tuner_settings_sheet.dart';

/// Practice tools modal with tab-based navigation between Metronome and Tuner.
class PracticeToolsModal extends ConsumerStatefulWidget {
  const PracticeToolsModal({super.key, this.initialTab = 0, this.studentId});

  /// Initial tab index (0 = Metronome, 1 = Tuner)
  final int initialTab;

  /// 학생 컨텍스트. null 이면 메트로놈 stop 시 [PracticeSourceLoggers] 트리거 안 함.
  /// 학생 게이미피케이션 P1 — Job 7 라우팅 진입점에서 주입.
  final String? studentId;

  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
    String? studentId,
  }) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          PracticeToolsModal(initialTab: initialTab, studentId: studentId),
    );
  }

  @override
  ConsumerState<PracticeToolsModal> createState() => _PracticeToolsModalState();
}

class _PracticeToolsModalState extends ConsumerState<PracticeToolsModal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    // Listen for tab changes to manage tuner microphone
    _tabController.addListener(_onTabChanged);

    // Pre-warm metronome and tuner only when tuner tab is opened.
    // Tuner should keep microphone inactive unless user enters tuner mode.
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();

      if (widget.initialTab == 1) {
        unawaited(_activateTunerProcessing());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // Stop tuner completely when modal closes (including stream)
    ref.read(tunerProvider.notifier).stopCompletely();
    super.dispose();
  }

  /// Handle tab changes - toggle tuner processing (instant, no blocking)
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final tuner = ref.read(tunerProvider.notifier);
    if (_tabController.index == 1) {
      // Switching TO tuner tab - warm and enable processing.
      unawaited(_activateTunerProcessing());
    } else {
      // Switching AWAY from tuner tab - clear tuner processing state.
      tuner.disableProcessing();
    }
  }

  Future<void> _activateTunerProcessing() async {
    if (!mounted) return;
    final tuner = ref.read(tunerProvider.notifier);
    await tuner.warmUp();
    if (!mounted || _tabController.index != 1) return;
    await tuner.enableProcessing();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tuner = ref.read(tunerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App going to background - stop tuner (not recording)
        tuner.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        if (_tabController.index == 1) {
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
                    tabs: const [
                      Tab(text: '메트로놈'),
                      Tab(text: '튜너'),
                    ],
                  ),
                ),
                // Settings button for tuner
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return _tabController.index == 1
                        ? IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => TunerSettingsSheet.show(context),
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
                MetronomePanel(studentId: widget.studentId),
                const TunerPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
