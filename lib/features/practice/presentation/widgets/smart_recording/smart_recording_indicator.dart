import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/smart_recording.dart';
import '../../../../../providers/smart_recording/smart_recording_provider.dart';

/// Indicator widget showing smart recording status during recording.
class SmartRecordingIndicator extends ConsumerWidget {
  const SmartRecordingIndicator({
    super.key,
    required this.isRecording,
  });

  final bool isRecording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(smartRecordingSettingsNotifierProvider);

    if (!settings.smartRecordingEnabled || !isRecording) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(smartRecordingNotifierProvider);

    return _buildIndicator(context, state);
  }

  Widget _buildIndicator(BuildContext context, SmartRecordingState state) {
    final (icon, label, color) = switch (state.phase) {
      RecordingPhase.waiting => (
          Icons.hourglass_empty,
          '대기 중... 연주를 시작하세요',
          AppColors.warning,
        ),
      RecordingPhase.recording => (
          Icons.fiber_manual_record,
          '녹음 중',
          AppColors.error,
        ),
      RecordingPhase.ending => (
          Icons.pause_circle_outline,
          '소리 감지 대기...',
          AppColors.textSecondaryLight,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result dialog showing trim results after recording.
class SmartRecordingResultDialog extends StatelessWidget {
  const SmartRecordingResultDialog({
    super.key,
    required this.trimmedStart,
    required this.trimmedEnd,
    required this.totalDuration,
    this.onRestore,
    this.onConfirm,
  });

  final Duration trimmedStart;
  final Duration trimmedEnd;
  final Duration totalDuration;
  final VoidCallback? onRestore;
  final VoidCallback? onConfirm;

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '$seconds초';
    }
    final minutes = duration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '$minutes분 $remainingSeconds초';
  }

  @override
  Widget build(BuildContext context) {
    final contentDuration = totalDuration - trimmedStart - trimmedEnd;
    final hasTrimming = trimmedStart > Duration.zero || trimmedEnd > Duration.zero;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('녹음 저장됨'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 길이: ${_formatDuration(contentDuration)}',
            style: AppTypography.bodyLarge,
          ),
          if (hasTrimming) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '스마트 녹음 적용:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (trimmedStart > Duration.zero)
              Row(
                children: [
                  const Icon(Icons.content_cut, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('앞 ${_formatDuration(trimmedStart)} 트림됨'),
                ],
              ),
            if (trimmedEnd > Duration.zero)
              Row(
                children: [
                  const Icon(Icons.content_cut, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('뒤 ${_formatDuration(trimmedEnd)} 트림됨'),
                ],
              ),
          ],
        ],
      ),
      actions: [
        if (hasTrimming && onRestore != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRestore?.call();
            },
            child: const Text('원본 복구'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// Show smart recording result dialog.
Future<void> showSmartRecordingResult(
  BuildContext context, {
  required Duration trimmedStart,
  required Duration trimmedEnd,
  required Duration totalDuration,
  VoidCallback? onRestore,
  VoidCallback? onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (context) => SmartRecordingResultDialog(
      trimmedStart: trimmedStart,
      trimmedEnd: trimmedEnd,
      totalDuration: totalDuration,
      onRestore: onRestore,
      onConfirm: onConfirm,
    ),
  );
}
