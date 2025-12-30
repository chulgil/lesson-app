import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/recording.dart';
import '../../../../providers/metronome/metronome_provider.dart';
import '../../../../providers/recording/recording_provider.dart';
import '../../../../services/audio_player_service.dart';

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

/// A-B Loop state for section repeat.
class ABLoop {
  const ABLoop({this.pointA, this.pointB});

  final Duration? pointA;
  final Duration? pointB;

  bool get isActive => pointA != null && pointB != null;
  bool get hasA => pointA != null;
  bool get hasB => pointB != null;

  ABLoop copyWith({Duration? pointA, Duration? pointB, bool clearA = false, bool clearB = false}) {
    return ABLoop(
      pointA: clearA ? null : (pointA ?? this.pointA),
      pointB: clearB ? null : (pointB ?? this.pointB),
    );
  }
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
      builder: (context) => RecordingPlayerSheet(
        recording: recording,
        repertoireId: repertoireId,
        studentId: studentId,
      ),
    );
  }

  @override
  ConsumerState<RecordingPlayerSheet> createState() => _RecordingPlayerSheetState();
}

class _RecordingPlayerSheetState extends ConsumerState<RecordingPlayerSheet> {
  PlaybackSpeed _speed = PlaybackSpeed.x1_0;
  ABLoop _abLoop = const ABLoop();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlaybackState>? _stateSub;

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

    // Listen to position updates
    _positionSub = _player.positionStream.listen((pos) {
      setState(() => _position = pos);

      // Handle A-B loop
      if (_abLoop.isActive && pos >= _abLoop.pointB!) {
        _player.seek(_abLoop.pointA!);
      }
    });

    // Listen to state changes
    _stateSub = _player.stateStream.listen((state) {
      setState(() {
        _isPlaying = state == PlaybackState.playing;
      });
    });
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
    final newPos = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    await _player.seek(newPos);
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

  @override
  Widget build(BuildContext context) {
    // Clamp progress to 0.0-1.0 range to prevent overflow
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
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
                widget.recording.title ?? _formatDate(widget.recording.recordedAt),
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.space4),

              // Waveform / Progress bar
              _WaveformProgressBar(
                progress: progress,
                abLoop: _abLoop,
                duration: _duration,
                onSeek: _seek,
              ),
              SizedBox(height: AppSpacing.space2),

              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: AppTypography.bodySmall.copyWith(color: Colors.grey[400]),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: AppTypography.bodySmall.copyWith(color: Colors.grey[400]),
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
                          color: _abLoop.isActive
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
                    itemBuilder: (context) => PlaybackSpeed.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontWeight: s == _speed ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ))
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
          border: isSet
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

/// Waveform-style progress bar.
class _WaveformProgressBar extends StatelessWidget {
  const _WaveformProgressBar({
    required this.progress,
    required this.abLoop,
    required this.duration,
    required this.onSeek,
  });

  final double progress;
  final ABLoop abLoop;
  final Duration duration;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = details.localPosition;
        final newProgress = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(newProgress);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = details.localPosition;
        final newProgress = (localPos.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(newProgress);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _WaveformPainter(
              progress: progress.clamp(0.0, 1.0),
              abLoop: abLoop,
              duration: duration,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for waveform visualization.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.abLoop,
    required this.duration,
  });

  final double progress;
  final ABLoop abLoop;
  final Duration duration;

  @override
  void paint(Canvas canvas, Size size) {
    final playedPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = const Color(0xFF636366)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final loopPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3);

    final markerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2;

    // Draw A-B loop highlight when both are set
    if (abLoop.isActive && duration.inMilliseconds > 0) {
      final aProgress = abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final bProgress = abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      final loopRect = Rect.fromLTRB(
        size.width * aProgress,
        0,
        size.width * bProgress,
        size.height,
      );
      canvas.drawRect(loopRect, loopPaint);
    }

    // Draw waveform bars
    const barCount = 50;
    final barWidth = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final barProgress = i / barCount;

      // Simulated waveform heights (in real implementation, use actual audio data)
      final height = (20 + (i % 7) * 5 + (i % 3) * 3).toDouble();
      final halfHeight = height / 2;

      final paint = barProgress <= progress ? playedPaint : unplayedPaint;

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }

    // Draw A marker (vertical line with label)
    if (abLoop.hasA && duration.inMilliseconds > 0) {
      final aProgress = abLoop.pointA!.inMilliseconds / duration.inMilliseconds;
      final aX = (size.width * aProgress).clamp(0.0, size.width);

      // Marker line (thicker)
      canvas.drawLine(
        Offset(aX, 0),
        Offset(aX, size.height),
        markerPaint..strokeWidth = 3,
      );

      // A label background (larger)
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(aX, 12), width: 22, height: 20),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelRect, Paint()..color = AppColors.primary);

      // A label text (larger font)
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(aX - 5, 5));
    }

    // Draw B marker (vertical line with label)
    if (abLoop.hasB && duration.inMilliseconds > 0) {
      final bProgress = abLoop.pointB!.inMilliseconds / duration.inMilliseconds;
      final bX = (size.width * bProgress).clamp(0.0, size.width);

      // Marker line (thicker)
      canvas.drawLine(
        Offset(bX, 0),
        Offset(bX, size.height),
        markerPaint..strokeWidth = 3,
      );

      // B label background (larger)
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bX, 12), width: 22, height: 20),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelRect, Paint()..color = AppColors.primary);

      // B label text (larger font)
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'B',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(bX - 5, 5));
    }

    // Draw playhead (clamped to prevent overflow)
    final clampedProgress = progress.clamp(0.0, 1.0);
    final playheadX = (size.width * clampedProgress).clamp(0.0, size.width);
    final playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(playheadX, 4),
      Offset(playheadX, size.height - 4),
      playheadPaint,
    );

    // Draw playhead knob (clamped to stay within bounds)
    final knobX = playheadX.clamp(6.0, size.width - 6.0);
    canvas.drawCircle(
      Offset(knobX, centerY),
      6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.abLoop != abLoop;
  }
}
