import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/recording.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../../../providers/recording/recording_provider.dart';
import '../../../../services/audio_player_service.dart';
import '../../../../services/audio_trimmer_service.dart';
import 'recording_waveform.dart' show ABLoop, ZoomableWaveformProgressBar;

/// Playback speed options.
enum PlaybackSpeed {
  x0_5(0.5, '0.5x'),
  x0_75(0.75, '0.75x'),
  x1_0(1.0, '1.0x'),
  x1_25(1.25, '1.25x'),
  x1_5(1.5, '1.5x'),
  x2_0(2.0, '2.0x');

  const PlaybackSpeed(this.value, this.label);
  final double value;
  final String label;
}

/// Bottom sheet player for recording playback.
/// iOS Voice Memos style with waveform visualization.
class RecordingPlayerSheet extends ConsumerStatefulWidget {
  const RecordingPlayerSheet({
    super.key,
    required this.recording,
    required this.repertoireId,
    required this.studentId,
  });

  final Recording recording;
  final String repertoireId;
  final String studentId;

  /// Show the player sheet.
  static Future<void> show(
    BuildContext context, {
    required Recording recording,
    required String repertoireId,
    required String studentId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RecordingPlayerSheet(
            recording: recording,
            repertoireId: repertoireId,
            studentId: studentId,
          ),
    );
  }

  @override
  ConsumerState<RecordingPlayerSheet> createState() =>
      _RecordingPlayerSheetState();
}

class _RecordingPlayerSheetState extends ConsumerState<RecordingPlayerSheet> {
  PlaybackSpeed _speed = PlaybackSpeed.x1_0;
  ABLoop _abLoop = const ABLoop();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _stateSub;

  // Trim metadata offset (contentStart in raw file)
  Duration _trimOffset = Duration.zero;
  Duration _trimEnd = Duration.zero;

  // Original metadata totalDuration for adjustment calculation
  Duration _metadataTotalDuration = Duration.zero;
  // trimEnd from metadata (silence duration to skip at end)
  Duration _trimEndSilence = Duration.zero;
  // Whether trim end has been adjusted for actual file duration
  bool _trimAdjusted = false;

  // Cache player reference to avoid using ref after dispose
  late final AudioPlayerService _player;

  @override
  void initState() {
    super.initState();
    _player = ref.read(audioPlayerServiceProvider);
    _duration = Duration(seconds: widget.recording.durationSeconds);
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    // Load the recording
    await _player.load(widget.recording.localPath);

    // Reset playback speed to default (1.0x) for new recording
    await _player.setSpeed(1.0);

    // Load trim metadata (fail-safe: ignore errors)
    await _loadTrimMetadata();

    // Seek to content start if trimmed
    if (_trimOffset > Duration.zero) {
      await _player.seek(_trimOffset);
    }

    // Listen to position updates
    _positionSub = _player.positionStream.listen((rawPos) {
      // Adjust _trimEnd based on actual file duration (Issue #16 fix)
      // This is needed because metadata's totalDuration may differ from actual file duration
      if (!_trimAdjusted &&
          _metadataTotalDuration > Duration.zero &&
          _player.duration > Duration.zero) {
        final actualDuration = _player.duration;
        final durationDiff = actualDuration - _metadataTotalDuration;
        if (durationDiff.abs() > const Duration(milliseconds: 200)) {
          // Adjust _trimEnd: actualDuration - trimEndSilence
          _trimEnd = actualDuration - _trimEndSilence;
        }
        _trimAdjusted = true;
      }

      // Convert raw position to display position (subtract trim offset)
      var displayPos = rawPos - _trimOffset;
      // Clamp to valid range
      if (displayPos < Duration.zero) displayPos = Duration.zero;
      if (displayPos > _duration) displayPos = _duration;
      setState(() => _position = displayPos);

      // Stop at content end if trimmed (only for non-segment playback)
      // Segment-based playback is handled by AudioPlayerService._handleSegmentPlayback
      final hasSegments = _player.hasSegments;
      if (!hasSegments && _trimEnd > Duration.zero && rawPos >= _trimEnd) {
        _player.pause();
        _player.seek(_trimOffset); // Reset to content start
      }

      // Handle A-B loop (using display positions, convert back for seek)
      if (_abLoop.isActive && displayPos >= _abLoop.pointB!) {
        _player.seek(_abLoop.pointA! + _trimOffset);
      }
    });

    // Listen to state changes
    _stateSub = _player.stateStream.listen((state) {
      setState(() {
        _isPlaying = state == PlaybackState.playing;
      });
    });
  }

  /// Load trim metadata from companion .trim file.
  Future<void> _loadTrimMetadata() async {
    try {
      final metadata = await AudioTrimmerService.instance.readTrimMetadata(
        widget.recording.localPath,
      );
      if (metadata != null && metadata.hasTrimming) {
        _trimOffset = metadata.contentStart;
        _trimEnd = metadata.contentEnd;
        // Save metadata values for later adjustment
        _metadataTotalDuration = metadata.totalDuration;
        _trimEndSilence = metadata.trimEnd;
        // Update duration to match actual content duration from metadata
        setState(() {
          _duration = metadata.contentDuration;
        });
      }
    } catch (e) {
      // Fail-safe: just use full file
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      // Stop metronome if playing (audio conflict on iOS)
      final metronomeState = ref.read(metronomeProvider);
      if (metronomeState.isPlaying) {
        ref.read(metronomeProvider.notifier).stop();
      }
      await _player.play();
    }
  }

  Future<void> _seek(double progress) async {
    // Calculate display position from progress
    final displayPos = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    // Convert to raw position by adding trim offset
    final rawPos = displayPos + _trimOffset;
    await _player.seek(rawPos);
  }

  /// Toggle point A: set if not set, clear if already set
  void _togglePointA() {
    setState(() {
      if (_abLoop.hasA) {
        // Clear both A and B
        _abLoop = const ABLoop();
      } else {
        // Set A to current position
        _abLoop = _abLoop.copyWith(pointA: _position);
      }
    });
  }

  /// Toggle point B: set if not set, clear if already set
  void _togglePointB() {
    if (!_abLoop.hasA) {
      // A must be set first - show feedback
      _showFeedback('먼저 A 지점을 설정하세요');
      return;
    }

    setState(() {
      if (_abLoop.hasB) {
        // Clear B only
        _abLoop = _abLoop.copyWith(clearB: true);
      } else if (_position > _abLoop.pointA!) {
        // Set B to current position (must be after A)
        _abLoop = _abLoop.copyWith(pointB: _position);
      } else {
        // Position is before or at A - show feedback
        _showFeedback('B는 A 이후 지점이어야 합니다');
      }
    });
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.15,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _changeSpeed(PlaybackSpeed speed) {
    setState(() => _speed = speed);
    _player.setSpeed(speed.value);
  }

  /// Handle A-B marker drag (using display positions)
  void _handleMarkerDrag(bool isA, double newProgress) {
    // A-B loop uses display positions (0 to _duration)
    final newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * newProgress).round(),
    );

    setState(() {
      if (isA) {
        // Ensure A is before B if B exists
        if (_abLoop.hasB && newPosition >= _abLoop.pointB!) {
          return;
        }
        _abLoop = _abLoop.copyWith(pointA: newPosition);
      } else {
        // Ensure B is after A
        if (_abLoop.hasA && newPosition <= _abLoop.pointA!) {
          return;
        }
        _abLoop = _abLoop.copyWith(pointB: newPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Clamp progress to 0.0-1.0 range to prevent overflow
    final progress =
        _duration.inMilliseconds > 0
            ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(
              0.0,
              1.0,
            )
            : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: AppSpacing.space4),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                widget.recording.title ??
                    _formatDate(widget.recording.recordedAt),
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space4),

              // Waveform / Progress bar with pinch zoom
              ZoomableWaveformProgressBar(
                progress: progress,
                abLoop: _abLoop,
                duration: _duration,
                onSeek: _seek,
                onABMarkerDrag: _handleMarkerDrag,
              ),
              SizedBox(height: AppSpacing.space2),

              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.space4),

              // Controls row: [A-B Loop] [Speed] ... [Play/Pause]
              Row(
                children: [
                  // A-B Loop toggle buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ABButton(
                        label: 'A',
                        isSet: _abLoop.hasA,
                        isEnabled: true,
                        onTap: _togglePointA,
                      ),
                      SizedBox(width: AppSpacing.space1),
                      // Connection line when loop is active
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _abLoop.isActive ? 16 : 8,
                        height: 2,
                        decoration: BoxDecoration(
                          color:
                              _abLoop.isActive
                                  ? AppColors.primary
                                  : Colors.grey[700],
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(width: AppSpacing.space1),
                      _ABButton(
                        label: 'B',
                        isSet: _abLoop.hasB,
                        isEnabled: _abLoop.hasA,
                        onTap: _togglePointB,
                      ),
                    ],
                  ),
                  SizedBox(width: AppSpacing.space3),

                  // Speed control
                  PopupMenuButton<PlaybackSpeed>(
                    onSelected: _changeSpeed,
                    itemBuilder:
                        (context) =>
                            PlaybackSpeed.values
                                .map(
                                  (s) => PopupMenuItem(
                                    value: s,
                                    child: Text(
                                      s.label,
                                      style: TextStyle(
                                        fontWeight:
                                            s == _speed
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _speed.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.space2),

                  // Share button
                  GestureDetector(
                    onTap: () => _shareToExternal(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.ios_share,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Play/Pause button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _togglePlay,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareToExternal(BuildContext context) async {
    final file = File(widget.recording.localPath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('녹음 파일을 찾을 수 없습니다')));
      }
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(widget.recording.localPath)]),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// A-B Loop toggle button widget.
class _ABButton extends StatelessWidget {
  const _ABButton({
    required this.label,
    required this.isSet,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isSet;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Determine button color based on state
    final Color backgroundColor;
    final Color textColor;

    if (!isEnabled) {
      // Disabled state
      backgroundColor = Colors.grey[900]!;
      textColor = Colors.grey[600]!;
    } else if (isSet) {
      // Active/set state
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else {
      // Enabled but not set
      backgroundColor = Colors.grey[800]!;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border:
              isSet
                  ? null
                  : Border.all(
                    color: isEnabled ? Colors.grey[600]! : Colors.grey[800]!,
                    width: 1,
                  ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
