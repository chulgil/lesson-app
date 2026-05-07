import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Reusable YouTube player with loop section markers.
///
/// Teacher mode: markers are draggable → user sets loop section.
/// Student mode: markers are fixed (from TeachingResource) → auto-loops.
// ignore: widget-smoke-test
class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;

  /// Pre-set start seconds (from TeachingResource). Null = start of video.
  final int? initialStartSeconds;

  /// Pre-set end seconds (from TeachingResource). Null = end of video.
  final int? initialEndSeconds;

  /// true = teacher can drag markers to adjust loop section.
  final bool isEditable;

  /// Called when the user adjusts the section markers (edit mode only).
  final ValueChanged<({int start, int end})>? onSectionChanged;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    this.initialStartSeconds,
    this.initialEndSeconds,
    this.isEditable = false,
    this.onSectionChanged,
  });

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;

  // Section boundaries in seconds (double for smoother drag)
  late double _startSeconds;
  late double _endSeconds;
  double _totalDuration = 1; // updated once video metadata arrives
  double _currentPosition = 0;
  bool _loopEnabled = true;
  bool _metadataReady = false;
  StreamSubscription<YoutubeVideoState>? _positionSub;

  @override
  void initState() {
    super.initState();
    _startSeconds = (widget.initialStartSeconds ?? 0).toDouble();
    _endSeconds = (widget.initialEndSeconds ?? 0).toDouble();
    // If endSeconds not provided we set it to 0; will be updated once metadata arrives.

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: _startSeconds > 0 ? _startSeconds : null,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        mute: false,
      ),
    );

    _controller.listen(_onPlayerEvent);
    _positionSub = _controller.videoStateStream.listen((state) {
      _onCurrentPosition(state.position);
    });
  }

  /// Called when player metadata changes (duration, state, etc.).
  void _onPlayerEvent(YoutubePlayerValue value) {
    if (!mounted) return;
    final duration = value.metaData.duration.inSeconds.toDouble();
    if (!_metadataReady && duration > 0) {
      setState(() {
        _metadataReady = true;
        _totalDuration = duration;
        // Default end to full duration if not pre-set
        if (_endSeconds <= 0) _endSeconds = duration;
        // Clamp to valid range
        if (_endSeconds > duration) _endSeconds = duration;
        if (_startSeconds > _endSeconds) _startSeconds = 0;
      });
    }
  }

  /// Called on each position tick from videoStateStream.
  void _onCurrentPosition(Duration position) {
    if (!mounted) return;
    final posSeconds = position.inSeconds.toDouble();
    setState(() => _currentPosition = posSeconds);

    // Loop logic: seek back to start when playhead passes end marker.
    if (_loopEnabled && _metadataReady && _endSeconds > _startSeconds) {
      if (posSeconds >= _endSeconds) {
        _controller.seekTo(seconds: _startSeconds, allowSeekAhead: true);
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _controller.close();
    super.dispose();
  }

  void _onStartDragUpdate(DragUpdateDetails details, double barWidth) {
    if (!widget.isEditable) return;
    final delta = details.delta.dx / barWidth * _totalDuration;
    setState(() {
      _startSeconds =
          (_startSeconds + delta).clamp(0, _endSeconds - 1).roundToDouble();
    });
    _notifySectionChanged();
  }

  void _onEndDragUpdate(DragUpdateDetails details, double barWidth) {
    if (!widget.isEditable) return;
    final delta = details.delta.dx / barWidth * _totalDuration;
    setState(() {
      _endSeconds =
          (_endSeconds + delta)
              .clamp(_startSeconds + 1, _totalDuration)
              .roundToDouble();
    });
    _notifySectionChanged();
  }

  void _notifySectionChanged() {
    widget.onSectionChanged?.call((
      start: _startSeconds.round(),
      end: _endSeconds.round(),
    ));
  }

  Future<void> _openInBrowser() async {
    final url =
        'https://www.youtube.com/watch?v=${widget.videoId}&t=${_startSeconds.round()}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // macOS: youtube_player_iframe 's WebView is not supported; show fallback.
    final isMacOs = !kIsWeb && Platform.isMacOS;
    if (isMacOs) {
      return _MacOsFallback(onOpenBrowser: _openInBrowser);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Video Player ──────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inkQuaternary),
            color: AppColors.paper,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _controller),
          ),
        ),

        const SizedBox(height: AppSpacing.space2),

        // ── Current time / total ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Row(
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: AppColors.inkTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatSeconds(_currentPosition.round())} / ${_formatSeconds(_totalDuration.round())}',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space2),

        // ── Progress bar with section markers ────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return _SectionProgressBar(
              currentPosition: _currentPosition,
              totalDuration: _totalDuration,
              startSeconds: _startSeconds,
              endSeconds: _endSeconds,
              barWidth: barWidth,
              isEditable: widget.isEditable,
              onStartDragUpdate: (d) => _onStartDragUpdate(d, barWidth),
              onEndDragUpdate: (d) => _onEndDragUpdate(d, barWidth),
            );
          },
        ),

        // ── Marker time labels ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.sectionStart} ${_formatSeconds(_startSeconds.round())}',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
              Text(
                '${AppStrings.sectionEnd} ${_formatSeconds(_endSeconds.round())}',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // ── Loop toggle ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Row(
            children: [
              Switch(
                value: _loopEnabled,
                onChanged: (v) => setState(() => _loopEnabled = v),
                activeThumbColor: AppColors.paperAccent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                _loopEnabled
                    ? AppStrings.loopSectionOn
                    : AppStrings.loopSectionOff,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space2),

        // ── Section display ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
          child: Row(
            children: [
              Text(
                '${AppStrings.sectionStart}:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                _formatSeconds(_startSeconds.round()),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.paperAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Text(
                '${AppStrings.sectionEnd}:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                _formatSeconds(_endSeconds.round()),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.paperAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Progress Bar ──────────────────────────────────────────────────────

class _SectionProgressBar extends StatelessWidget {
  final double currentPosition;
  final double totalDuration;
  final double startSeconds;
  final double endSeconds;
  final double barWidth;
  final bool isEditable;
  final ValueChanged<DragUpdateDetails> onStartDragUpdate;
  final ValueChanged<DragUpdateDetails> onEndDragUpdate;

  static const double _barHeight = 6;
  static const double _markerRadius = 8;

  const _SectionProgressBar({
    required this.currentPosition,
    required this.totalDuration,
    required this.startSeconds,
    required this.endSeconds,
    required this.barWidth,
    required this.isEditable,
    required this.onStartDragUpdate,
    required this.onEndDragUpdate,
  });

  double _positionFraction(double seconds) {
    if (totalDuration <= 0) return 0;
    return (seconds / totalDuration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final startFraction = _positionFraction(startSeconds);
    final endFraction = _positionFraction(endSeconds);
    final progressFraction = _positionFraction(currentPosition);

    return SizedBox(
      height: _markerRadius * 2 + 4,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Track background
          Container(
            height: _barHeight,
            decoration: BoxDecoration(
              color: AppColors.inkQuaternary,
              borderRadius: BorderRadius.circular(_barHeight / 2),
            ),
          ),

          // Progress fill (playhead)
          FractionallySizedBox(
            widthFactor: progressFraction,
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(_barHeight / 2),
              ),
            ),
          ),

          // Section fill between markers
          Positioned(
            left: startFraction * barWidth,
            width: (endFraction - startFraction) * barWidth,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                height: _barHeight,
                color: AppColors.paperAccentSoft,
              ),
            ),
          ),

          // Start marker
          Positioned(
            left: startFraction * barWidth - _markerRadius,
            child: GestureDetector(
              onHorizontalDragUpdate: isEditable ? onStartDragUpdate : null,
              child: _Marker(isEditable: isEditable),
            ),
          ),

          // End marker
          Positioned(
            left: endFraction * barWidth - _markerRadius,
            child: GestureDetector(
              onHorizontalDragUpdate: isEditable ? onEndDragUpdate : null,
              child: _Marker(isEditable: isEditable),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final bool isEditable;

  static const double _radius = 8;

  const _Marker({required this.isEditable});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _radius * 2,
      height: _radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paperAccent,
        boxShadow:
            isEditable
                ? [
                  BoxShadow(
                    color: AppColors.paperAccent.withValues(alpha: 0.35),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
    );
  }
}

// ── macOS fallback ────────────────────────────────────────────────────────────

class _MacOsFallback extends StatelessWidget {
  final VoidCallback onOpenBrowser;

  const _MacOsFallback({required this.onOpenBrowser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
        color: AppColors.paperDark,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.open_in_browser,
              size: 36,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.youtubePlayerMacOsFallback,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space3),
            FilledButton(
              onPressed: onOpenBrowser,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
              child: const Text(AppStrings.youtubePlayerOpenExternal),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatSeconds(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
