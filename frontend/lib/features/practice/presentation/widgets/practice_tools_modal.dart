import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/practice/presentation/providers/metronome_provider.dart';
import '../providers/tuner_provider.dart';
import 'practice_tools/metronome_panel.dart';
import 'practice_tools/tuner_panel.dart';
import 'tuner/tuner_settings_sheet.dart';

/// Practice tools modal with tab-based navigation between Metronome and Tuner.
class PracticeToolsModal extends ConsumerStatefulWidget {
  const PracticeToolsModal({super.key, this.initialTab = 0});

  /// Initial tab index (0 = Metronome, 1 = Tuner)
  final int initialTab;

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PracticeToolsModal(initialTab: initialTab),
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

    // Pre-warm both metronome and tuner engines
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();

      // Warm up tuner (starts microphone stream without processing)
      // This is done once when modal opens, so tab switching is instant
      ref.read(tunerProvider.notifier).warmUp().then((_) {
        if (!mounted) return;

        // If starting on tuner tab, enable processing after warm-up
        if (widget.initialTab == 1) {
          ref.read(tunerProvider.notifier).enableProcessing();
        }
      });
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
      // Switching TO tuner tab - enable processing (instant!)
      // Stream is already active from warmUp, so no blocking occurs
      tuner.enableProcessing();
    } else {
      // Switching AWAY from tuner tab - disable processing
      // Stream stays active for instant re-enabling
      tuner.disableProcessing();
    }
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
          // On other tab - re-warm stream so switching to tuner tab later works
          tuner.warmUp();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    tabs: const [Tab(text: '메트로놈'), Tab(text: '튜너')],
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
              children: const [MetronomePanel(), TunerPanel()],
            ),
          ),
        ],
      ),
    );
  }
}
