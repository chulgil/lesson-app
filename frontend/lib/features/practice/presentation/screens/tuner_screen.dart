import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/tuner_provider.dart';
import '../widgets/tuner/circular_tuner_indicator.dart';
import '../widgets/tuner/normalized_staff_widget.dart';
import '../widgets/tuner/tuner_cat_indicator.dart';
import '../widgets/tuner/tuner_settings_sheet.dart';

/// Main tuner screen with circular indicator and cat feedback.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Auto-start listening when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tunerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    // Stop tuner when leaving screen
    ref.read(tunerProvider.notifier).stop();
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final tuner = ref.read(tunerProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - stop listening
        tuner.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App returning to foreground - resume listening
        tuner.onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Do nothing for these states
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);

    return Scaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text('튜너'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => TunerSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content layer (tuner area with starburst animation)
            Column(
              children: [
                // Main tuner area - responsive to screen size
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;

                      // Use the smaller dimension
                      final availableSize = availableWidth < availableHeight
                          ? availableWidth
                          : availableHeight;

                      // Calculate scale factor (base size 400 for circle + indicators)
                      final scaleFactor = (availableSize / 450).clamp(0.5, 1.2);

                      return Center(
                        child: Transform.scale(
                          scale: scaleFactor,
                          child: const CircularTunerIndicator(
                            size: 280,
                            centerChild: TunerCatIndicator(size: 200),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Spacer to match the bottom section height
                const SizedBox(height: 162), // 16 + 70 + 12 + 32 + 32
              ],
            ),

            // Top layer - Staff and Info bar (always visible above starburst)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.paperDark,
                padding: const EdgeInsets.only(top: AppSpacing.space4, bottom: AppSpacing.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Staff display
                    NormalizedStaffWidget(
                      note: tunerState.currentNote,
                      isPerfect: tunerState.isPerfect,
                      width: 140,
                      height: 70,
                    ),

                    const SizedBox(height: AppSpacing.space3),

                    // Info bar
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space8),
                      child: TunerInfoBar(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact tuner widget for embedding in other screens.
class CompactTunerWidget extends ConsumerWidget {
  const CompactTunerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunerState = ref.watch(tunerProvider);
    final isListening = tunerState.isListening;
    final currentNote = tunerState.currentNote;

    return GestureDetector(
      onTap: () => ref.read(tunerProvider.notifier).toggle(),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          border: Border.all(
            color: isListening ? AppColors.primary : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.graphic_eq : Icons.mic_none,
              color: isListening ? AppColors.primary : AppColors.inkTertiary,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              currentNote?.fullName ?? (isListening ? '감지 중...' : '튜너'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isListening ? AppColors.primary : AppColors.inkSecondary,
              ),
            ),
            if (currentNote != null) ...[
              const SizedBox(width: AppSpacing.space1),
              Text(
                currentNote.centDisplayString,
                style: AppTypography.bodySmall.copyWith(
                  color: tunerState.isPerfect ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
