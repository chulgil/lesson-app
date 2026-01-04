import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/tuner_provider.dart';
import '../widgets/tuner/circular_tuner_indicator.dart';
import '../widgets/tuner/tuner_cat_indicator.dart';
import '../widgets/tuner/tuner_settings_sheet.dart';

/// Main tuner screen with circular indicator and cat feedback.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start listening when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tunerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    // Stop listening when leaving screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tunerState = ref.watch(tunerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
        child: Column(
          children: [
            // Main tuner area
            Expanded(
              child: Center(
                child: CircularTunerIndicator(
                  size: 300,
                  centerChild: const TunerCatIndicator(size: 100),
                ),
              ),
            ),

            // Info bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: TunerInfoBar(),
            ),

            const SizedBox(height: 24),

            // Start/Stop button
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _TunerButton(
                isListening: tunerState.isListening,
                onPressed: () {
                  ref.read(tunerProvider.notifier).toggle();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large circular button to start/stop tuner.
class _TunerButton extends StatelessWidget {
  const _TunerButton({
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? AppColors.error : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (isListening ? AppColors.error : AppColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          size: 36,
          color: Colors.white,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isListening ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.graphic_eq : Icons.mic_none,
              color: isListening ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              currentNote?.fullName ?? (isListening ? '감지 중...' : '튜너'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isListening ? AppColors.primary : Colors.grey[600],
              ),
            ),
            if (currentNote != null) ...[
              const SizedBox(width: 4),
              Text(
                currentNote.centDisplayString,
                style: TextStyle(
                  fontSize: 12,
                  color: tunerState.isPerfect ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
