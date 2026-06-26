import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Step 3: Recording simulation widget for student tutorial
///
/// Simulates a long-press recording interaction (2+ seconds) with visual feedback.
/// Shows progress as duration increases, displays auto-trimming result card on completion.
class RecordingStep extends StatefulWidget {
  final bool completed;
  final VoidCallback onComplete;

  const RecordingStep({
    super.key,
    required this.completed,
    required this.onComplete,
  });

  @override
  State<RecordingStep> createState() => _RecordingStepState();
}

class _RecordingStepState extends State<RecordingStep> {
  double _pressDuration = 0.0;
  Timer? _pressTimer;
  bool _hasCompleted = false;

  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }

  void _onLongPressStart() {
    if (_hasCompleted || widget.completed) return;

    setState(() {
      _pressDuration = 0.0;
    });

    _pressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _pressDuration += 0.1;
      });
    });
  }

  void _onLongPressEnd() {
    _pressTimer?.cancel();

    if (_pressDuration >= 2.0) {
      setState(() {
        _hasCompleted = true;
      });
      widget.onComplete();
    } else {
      setState(() {
        _pressDuration = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _pressTimer != null && _pressTimer!.isActive;
    final isComplete = _hasCompleted || widget.completed;

    // 버그 B: 부모 _StudentTutorialPage 가 이미 SingleChildScrollView 이므로
    // 중첩 스크롤(중복 제스처 인식기) 제거 → Padding 단독.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space5,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Instruction text
          if (!isComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space5),
              child: Text(
                AppStrings.recordingStepGuide,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),

          // Recording button
          if (!isComplete)
            Column(
              children: [
                GestureDetector(
                  key: const ValueKey('student_tutorial_recording_button'),
                  onLongPressStart: (_) => _onLongPressStart(),
                  onLongPressEnd: (_) => _onLongPressEnd(),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color:
                          isRecording ? AppColors.paperAccent : AppColors.paper,
                      border: Border.all(
                        color:
                            isRecording
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      size: 48,
                      color:
                          isRecording ? AppColors.paper : AppColors.inkTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Recording duration text
                if (isRecording)
                  Text(
                    AppStrings.recordingInProgressSeconds(_pressDuration.toStringAsFixed(1)),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                // Progress indicator
                if (isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space3),
                    child: SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _pressDuration / 2.0,
                        minHeight: 4.0,
                        backgroundColor: AppColors.inkQuaternary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.paperAccent,
                        ),
                      ),
                    ),
                  ),

                // Too short message
                if (!isRecording && _pressDuration > 0 && _pressDuration < 2.0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space3),
                    child: Text(
                      AppStrings.recordingStepHoldLonger,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ),
              ],
            ),

          // Result card (shown when completed or completed prop is true)
          if (isComplete)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                border: Border.all(color: AppColors.paperAccent, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.paperOk,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      AppStrings.recordingStepTrimInfo,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
