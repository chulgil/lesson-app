// Recording control widget

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../providers/recording/recording_provider.dart';
import '../../../../../providers/smart_recording/smart_recording_provider.dart';
import '../recording_waveform.dart';
import '../smart_recording/smart_recording_indicator.dart';

/// Recording control widget with start/pause/stop functionality
class RecordingControl extends ConsumerStatefulWidget {
  final bool isRecording;
  final bool isPaused;
  final int recordingSeconds;
  final VoidCallback onStartRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;
  final VoidCallback onStopRecording;
  final VoidCallback? onResetRecording;

  const RecordingControl({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.recordingSeconds,
    required this.onStartRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
    required this.onStopRecording,
    this.onResetRecording,
  });

  @override
  ConsumerState<RecordingControl> createState() => _RecordingControlState();
}

class _RecordingControlState extends ConsumerState<RecordingControl> {
  // Thresholds for amplitude detection
  static const _noInputThreshold = 0.05;
  static const _quietThreshold = 0.40;
  static const _micCheckDuration = Duration(milliseconds: 1500);

  bool _hasMicInput = true;
  bool _isQuiet = false;
  StreamSubscription<double>? _micCheckSubscription;
  DateTime? _recordingStartTime;

  String get _formattedTime {
    final minutes = widget.recordingSeconds ~/ 60;
    final seconds = widget.recordingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void didUpdateWidget(covariant RecordingControl oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording && !oldWidget.isRecording) {
      _startMicInputCheck();
    }

    if (!widget.isRecording && oldWidget.isRecording) {
      _stopMicInputCheck();
      setState(() {
        _hasMicInput = true;
        _isQuiet = false;
      });
    }
  }

  void _startMicInputCheck() {
    _micCheckSubscription?.cancel();
    _recordingStartTime = DateTime.now();

    final recorder = ref.read(audioRecorderServiceProvider);
    _micCheckSubscription = recorder.normalizedAmplitudeStream.listen((amplitude) {
      final now = DateTime.now();

      if (amplitude >= _quietThreshold) {
        if (!_hasMicInput || _isQuiet) {
          setState(() {
            _hasMicInput = true;
            _isQuiet = false;
          });
        }
        return;
      }

      if (amplitude >= _noInputThreshold && amplitude < _quietThreshold) {
        if (_recordingStartTime != null &&
            now.difference(_recordingStartTime!) >= _micCheckDuration) {
          if (!_isQuiet && widget.isRecording) {
            setState(() {
              _hasMicInput = true;
              _isQuiet = true;
            });
          }
        }
        return;
      }

      if (_recordingStartTime != null &&
          now.difference(_recordingStartTime!) >= _micCheckDuration) {
        if (_hasMicInput && widget.isRecording) {
          setState(() {
            _hasMicInput = false;
            _isQuiet = false;
          });
        }
      }
    });
  }

  void _stopMicInputCheck() {
    _micCheckSubscription?.cancel();
    _micCheckSubscription = null;
    _recordingStartTime = null;
  }

  @override
  void dispose() {
    _stopMicInputCheck();
    super.dispose();
  }

  /// Build a circular control button with consistent styling
  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    String? tooltip,
  }) {
    return SizedBox(
      width: 80,
      height: 80,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 40),
        style: IconButton.styleFrom(backgroundColor: backgroundColor),
        tooltip: tooltip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amplitudeStream = widget.isRecording
        ? ref.read(audioRecorderServiceProvider).normalizedAmplitudeStream
        : null;

    final micPermissionAsync = ref.watch(microphonePermissionProvider);
    final hasMicPermission = micPermissionAsync.valueOrNull ?? false;

    final smartSettings = ref.watch(smartRecordingSettingsNotifierProvider);
    final isSmartMode = smartSettings.smartRecordingEnabled;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isRecording
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: widget.isRecording
                ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                : null,
          ),
          child: Stack(
            children: [
              if (widget.isRecording)
                Positioned.fill(
                  child: RecordingWaveform(
                    style: WaveformStyle.amplitude,
                    isActive: !widget.isPaused,
                    height: 200,
                    waveColor: Colors.white.withValues(alpha: 0.6),
                    amplitudeStream: amplitudeStream,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space6,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isRecording && isSmartMode) ...[
                      SmartRecordingIndicator(isRecording: widget.isRecording),
                      const SizedBox(height: AppSpacing.space2),
                    ],
                    if (widget.isRecording) ...[
                      if (!isSmartMode) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: widget.isPaused ? AppColors.warning : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isPaused ? '일시정지' : '녹음 중',
                              style: AppTypography.bodyMedium.copyWith(
                                color: widget.isPaused ? AppColors.warning : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ],
                      Text(
                        _formattedTime,
                        style: AppTypography.headingLarge.copyWith(
                          fontSize: 36,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Reset button - restart recording from this moment
                          if (widget.onResetRecording != null) ...[
                            _buildControlButton(
                              onPressed: widget.onResetRecording!,
                              icon: Icons.refresh,
                              backgroundColor: AppColors.catAccent,
                              tooltip: '녹음 초기화',
                            ),
                            const SizedBox(width: AppSpacing.space4),
                          ],
                          // Pause/Resume button
                          _buildControlButton(
                            onPressed: widget.isPaused
                                ? widget.onResumeRecording
                                : widget.onPauseRecording,
                            icon: widget.isPaused ? Icons.play_arrow : Icons.pause,
                            backgroundColor: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.space4),
                          // Stop button
                          _buildControlButton(
                            onPressed: widget.onStopRecording,
                            icon: Icons.stop,
                            backgroundColor: AppColors.error,
                          ),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: FilledButton(
                        onPressed: hasMicPermission ? widget.onStartRecording : () async {
                          final granted = await ref.read(audioRecorderServiceProvider).requestPermission();
                          if (granted) {
                            ref.invalidate(microphonePermissionProvider);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.')),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: hasMicPermission ? AppColors.error : AppColors.textSecondaryLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space8,
                            vertical: AppSpacing.space4,
                          ),
                          fixedSize: const Size.fromHeight(56),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasMicPermission ? Icons.mic : Icons.mic_off,
                              size: 28,
                              color: Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Text(
                              !hasMicPermission
                                  ? '마이크 권한 필요'
                                  : isSmartMode
                                      ? '스마트 녹음'
                                      : '녹음 시작',
                              style: AppTypography.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
