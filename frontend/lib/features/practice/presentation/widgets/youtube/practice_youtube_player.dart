import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/practice_loop_override.dart';
import '../../../domain/services/playback_looper.dart';
import '../../../domain/services/youtube_ad_detector.dart';
import '../../../domain/value_objects/practice_loop_speeds.dart';
import '../../providers/practice_loop_provider.dart';
import '../../providers/practice_loop_stats_provider.dart';
import '../../providers/practice_youtube_pause_signal.dart';
import 'ad_notice_overlay.dart';
import 'count_in_overlay.dart';
import 'loop_controls.dart';
import 'loop_memo_overlay.dart';
import 'loop_timeline.dart';
import 'repeat_counter.dart';

/// Main practice player — embeds the YouTube iframe, timeline, controls, and
/// repeat counter inside a single notebook-styled column.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.2
// ignore: widget-smoke-test
class PracticeYoutubePlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String sectionId;
  final int? teacherStartSeconds;
  final int? teacherEndSeconds;

  const PracticeYoutubePlayer({
    super.key,
    required this.videoId,
    required this.sectionId,
    this.teacherStartSeconds,
    this.teacherEndSeconds,
  });

  @override
  ConsumerState<PracticeYoutubePlayer> createState() =>
      _PracticeYoutubePlayerState();
}

class _PracticeYoutubePlayerState extends ConsumerState<PracticeYoutubePlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubeVideoState>? _videoStateSub;

  double _currentPosition = 0;
  double _totalDuration = 1;
  bool _metadataReady = false;
  bool _showCountIn = false;
  bool _seekInFlight = false;

  /// §3.5 #509 — heuristic ad detector + auto-pause state.
  final YoutubeAdDetector _adDetector = YoutubeAdDetector();
  bool _showAdNotice = false;
  bool _adAutoPausedOnce = false;

  @override
  void initState() {
    super.initState();
    if (!_supportsIframe) return;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      startSeconds: (widget.teacherStartSeconds ?? 0) > 0
          ? widget.teacherStartSeconds!.toDouble()
          : null,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        playsInline: true,
        mute: false,
      ),
    );
    _videoStateSub = _controller!.videoStateStream.listen(_onVideoState);
    _controller!.listen(_onPlayerEvent);
  }

  bool get _supportsIframe => kIsWeb || !Platform.isMacOS;

  void _onPlayerEvent(YoutubePlayerValue value) {
    if (!mounted) return;
    final dur = value.metaData.duration.inSeconds.toDouble();
    if (!_metadataReady && dur > 0) {
      setState(() {
        _metadataReady = true;
        _totalDuration = dur;
      });
    }

    // §3.5 #509 — clear ad-flag when player leaves the playing state for
    // a non-buffering reason (paused, ended, cued). Buffering can occur
    // mid-ad so we leave the flag alone there.
    final st = value.playerState;
    if (st == PlayerState.paused ||
        st == PlayerState.ended ||
        st == PlayerState.cued) {
      _adDetector.onResumeOrPause();
    }
  }

  void _onVideoState(YoutubeVideoState state) {
    if (!mounted) return;
    final pos = state.position.inSeconds.toDouble();

    // §3.5 #509 — feed the detector before computing the loop decision so
    // ad windows protect the repeat counter (best effort).
    final isPlaying = _controller?.value.playerState == PlayerState.playing;
    final adActive = _adDetector.observe(
      positionSeconds: pos,
      isPlaying: isPlaying,
    );

    setState(() {
      _currentPosition = pos;
      _showAdNotice = adActive;
    });

    if (adActive && !_adAutoPausedOnce) {
      _adAutoPausedOnce = true;
      _controller?.pauseVideo();
    } else if (!adActive) {
      _adAutoPausedOnce = false;
    }

    final overrideAsync = ref.read(
      practiceLoopOverrideNotifierProvider(widget.sectionId),
    );
    final override = overrideAsync.valueOrNull;
    if (override == null) return;

    final start = override.effectiveStartSeconds(widget.teacherStartSeconds);
    final endRaw = override.effectiveEndSeconds(widget.teacherEndSeconds);
    if (endRaw == null) return;

    final looper = PlaybackLooper(
      startSeconds: start,
      endSeconds: endRaw,
      targetRepeatCount: override.targetRepeatCount,
      loopEnabled: true, // gated externally via play/pause
      countInEnabled: override.countInEnabled,
    );
    final decision = looper.evaluate(
      positionSeconds: pos,
      completedCount: override.completedRepeatCount,
      isAdPlaying: adActive,
    );
    _handleDecision(decision);
  }

  /// §3.5 #509 — manual resume after the user confirms the ad ended.
  Future<void> _onResumeFromAd() async {
    _adDetector.onResumeOrPause();
    _adAutoPausedOnce = false;
    if (mounted) {
      setState(() => _showAdNotice = false);
    }
    await _controller?.playVideo();
  }

  Future<void> _handleDecision(PlaybackLoopDecision decision) async {
    if (_seekInFlight) return;
    switch (decision.action) {
      case PlaybackLoopAction.continuePlaying:
        return;
      case PlaybackLoopAction.seekBack:
        _seekInFlight = true;
        _adDetector.onExplicitSeek();
        await _controller?.seekTo(
          seconds: (decision.seekToSeconds ?? 0).toDouble(),
          allowSeekAhead: true,
        );
        await ref
            .read(
              practiceLoopOverrideNotifierProvider(widget.sectionId).notifier,
            )
            .incrementCompletedCount();
        _seekInFlight = false;
        break;
      case PlaybackLoopAction.countInThenSeekBack:
        _seekInFlight = true;
        await _controller?.pauseVideo();
        if (!mounted) {
          _seekInFlight = false;
          return;
        }
        setState(() => _showCountIn = true);
        break;
      case PlaybackLoopAction.countInThenPlay:
        // Only triggered by manual play tap.
        if (!mounted) return;
        setState(() => _showCountIn = true);
        break;
      case PlaybackLoopAction.completeTarget:
        await _controller?.pauseVideo();
        await ref
            .read(
              practiceLoopOverrideNotifierProvider(widget.sectionId).notifier,
            )
            .incrementCompletedCount();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.youtubeLoopTargetReached),
            backgroundColor: AppColors.paperOk,
          ),
        );
        break;
    }
  }

  Future<void> _onCountInCompleted() async {
    if (!mounted) return;
    setState(() => _showCountIn = false);
    final override = ref
        .read(practiceLoopOverrideNotifierProvider(widget.sectionId))
        .valueOrNull;
    final start =
        override?.effectiveStartSeconds(widget.teacherStartSeconds) ??
        widget.teacherStartSeconds ??
        0;
    await _controller?.seekTo(seconds: start.toDouble(), allowSeekAhead: true);
    await _controller?.playVideo();
    await ref
        .read(practiceLoopOverrideNotifierProvider(widget.sectionId).notifier)
        .incrementCompletedCount();
    _seekInFlight = false;
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _videoStateSub?.cancel();
    _controller?.close();
    // #512 — session end: flush the loop stats queue. Best-effort; the queue
    // persists across failures so the next session retries automatically.
    // ignore: unawaited_futures
    ref.read(loopStatsSyncActionsProvider).flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsIframe) {
      return _MacOsFallback(onOpenBrowser: _openInBrowser);
    }
    final overrideAsync = ref.watch(
      practiceLoopOverrideNotifierProvider(widget.sectionId),
    );

    // §3.5 entry-point 5: pause when recording stops or result UI opens.
    ref.listen<int>(practiceYoutubePauseTickerProvider, (prev, next) {
      if (prev != null && prev != next) {
        _controller?.pauseVideo();
      }
    });

    return overrideAsync.when(
      data: (override) => _buildContent(override),
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildError(),
    );
  }

  Widget _buildContent(PracticeLoopOverride override) {
    final start = override.effectiveStartSeconds(widget.teacherStartSeconds);
    final end =
        override.effectiveEndSeconds(widget.teacherEndSeconds)?.toDouble() ??
        _totalDuration;
    final notifier = ref.read(
      practiceLoopOverrideNotifierProvider(widget.sectionId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video canvas (ink backdrop — Notebook deep ink behind media).
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Container(
                color: AppColors.ink,
                child: YoutubePlayer(controller: _controller!),
              ),
              // Memo overlay (#510) — only when count-in is not active.
              if (!_showCountIn)
                Positioned.fill(
                  child: LoopMemoOverlay(
                    memos: override.studentMemos,
                    currentPositionSeconds: _currentPosition.round(),
                    onAdd: (text) => notifier.addMemo(
                      atSeconds: _currentPosition.round(),
                      text: text,
                    ),
                    onEdit: (memo, text) =>
                        notifier.updateMemo(id: memo.id, text: text),
                    onDelete: (memo) => notifier.deleteMemo(memo.id),
                  ),
                ),
              if (_showCountIn)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x33000000),
                    child: CountInOverlay(onCompleted: _onCountInCompleted),
                  ),
                ),
            ],
          ),
        ),
        // §3.5 #509 — ad notice + manual resume.
        if (_showAdNotice) ...[
          const SizedBox(height: AppSpacing.space2),
          AdNoticeOverlay(onResume: _onResumeFromAd),
        ],
        const SizedBox(height: AppSpacing.space2),
        LoopTimeline(
          totalDurationSeconds: _totalDuration,
          currentPositionSeconds: _currentPosition,
          startSeconds: start.toDouble(),
          endSeconds: end,
          memoSeconds: override.studentMemos.map((m) => m.atSeconds).toList(),
          onStartChanged: (v) => notifier.setSegment(
            startSeconds: v.round(),
            endSeconds: end.round(),
          ),
          onEndChanged: (v) =>
              notifier.setSegment(startSeconds: start, endSeconds: v.round()),
        ),
        const SizedBox(height: AppSpacing.space2),
        LoopControls(
          repeatEnabled: true,
          onRepeatChanged: (_) {}, // loop is always on inside this widget
          speed: override.playbackSpeed,
          onSpeedChanged: (v) async {
            await notifier.setSpeed(v);
            await _controller?.setPlaybackRate(v);
          },
          onReset: () => notifier.resetSegment(),
          countInEnabled: override.countInEnabled,
          onCountInChanged: notifier.setCountInEnabled,
          countInSoundEnabled: override.countInSoundEnabled,
          onCountInSoundChanged: notifier.setCountInSoundEnabled,
        ),
        const SizedBox(height: AppSpacing.space2),
        RepeatCounter(
          completed: override.completedRepeatCount,
          target: override.targetRepeatCount,
          onTargetChanged: (v) => notifier.setTargetRepeatCount(v),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        children: [
          Text(
            AppStrings.youtubeLoopVideoUnavailable,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          FilledButton(
            onPressed: _openInBrowser,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text(AppStrings.youtubeLoopOpenExternal),
          ),
        ],
      ),
    );
  }
}

class _MacOsFallback extends StatelessWidget {
  final VoidCallback onOpenBrowser;

  const _MacOsFallback({required this.onOpenBrowser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paperDark),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.youtubeLoopVideoUnavailable,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            FilledButton(
              onPressed: onOpenBrowser,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(AppStrings.youtubeLoopOpenExternal),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep PracticeLoopSpeeds referenced to avoid analyzer unused import warning
// (used indirectly through LoopControls but importing here for clarity in tests).
// ignore: unused_element
const _kAllowedSpeeds = PracticeLoopSpeeds.allowed;
