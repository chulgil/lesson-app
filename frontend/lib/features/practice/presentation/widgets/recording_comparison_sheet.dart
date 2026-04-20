import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../providers/recording_comparison_provider.dart';
import 'waveform/zoomable_waveform.dart';

/// Shows the recording comparison bottom sheet.
/// [recordings] must be sorted by createdAt ascending.
void showRecordingComparisonSheet(
  BuildContext context,
  List<PracticeRecording> recordings,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder:
              (context, scrollController) => _RecordingComparisonSheet(
                recordings: recordings,
                scrollController: scrollController,
              ),
        ),
  );
}

class _RecordingComparisonSheet extends StatefulWidget {
  const _RecordingComparisonSheet({
    required this.recordings,
    required this.scrollController,
  });

  final List<PracticeRecording> recordings;
  final ScrollController scrollController;

  @override
  State<_RecordingComparisonSheet> createState() =>
      _RecordingComparisonSheetState();
}

class _RecordingComparisonSheetState extends State<_RecordingComparisonSheet> {
  int _step = 0; // 0: select A, 1: select B, 2: compare
  PracticeRecording? _recordingA;
  PracticeRecording? _recordingB;

  // Audio players
  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  bool _playingA = false;
  bool _playingB = false;
  bool _alternateMode = false;
  bool _parallelMode = false; // Phase 2: parallel waveform mode
  double _playbackRate = 1.0; // Phase 2: speed control
  Duration _positionA = Duration.zero;
  Duration _durationA = Duration.zero;
  Duration _positionB = Duration.zero;
  Duration _durationB = Duration.zero;
  StreamSubscription<PlayerState>? _stateSubA;
  StreamSubscription<PlayerState>? _stateSubB;
  StreamSubscription<Duration>? _posSubA;
  StreamSubscription<Duration>? _posSubB;
  StreamSubscription<Duration>? _durSubA;
  StreamSubscription<Duration>? _durSubB;

  @override
  void dispose() {
    _stateSubA?.cancel();
    _stateSubB?.cancel();
    _posSubA?.cancel();
    _posSubB?.cancel();
    _durSubA?.cancel();
    _durSubB?.cancel();
    _playerA.dispose();
    _playerB.dispose();
    super.dispose();
  }

  void _selectA(PracticeRecording rec) {
    setState(() {
      _recordingA = rec;
      _step = 1;
    });
  }

  void _selectB(PracticeRecording rec) {
    setState(() {
      _recordingB = rec;
      _step = 2;
    });
    _setupPlayers();
  }

  void _setupPlayers() {
    _posSubA = _playerA.onPositionChanged.listen((p) {
      if (mounted) setState(() => _positionA = p);
    });
    _durSubA = _playerA.onDurationChanged.listen((d) {
      if (mounted) setState(() => _durationA = d);
    });
    _posSubB = _playerB.onPositionChanged.listen((p) {
      if (mounted) setState(() => _positionB = p);
    });
    _durSubB = _playerB.onDurationChanged.listen((d) {
      if (mounted) setState(() => _durationB = d);
    });
    _stateSubA = _playerA.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playingA = state == PlayerState.playing);
        if (state == PlayerState.completed && _alternateMode) {
          _playB();
        }
      }
    });
    _stateSubB = _playerB.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playingB = state == PlayerState.playing);
    });
  }

  Future<void> _playA() async {
    await _playerB.stop();
    await _playerA.play(DeviceFileSource(_recordingA!.filePath));
  }

  Future<void> _playB() async {
    await _playerA.stop();
    await _playerB.play(DeviceFileSource(_recordingB!.filePath));
  }

  Future<void> _stopAll() async {
    await _playerA.stop();
    await _playerB.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: switch (_step) {
              0 => _buildSelectStep(
                label: 'Step 1/2: 이전 녹음 선택',
                recordings: widget.recordings,
                selected: _recordingA,
                onSelect: _selectA,
              ),
              1 => _buildSelectStep(
                label: 'Step 2/2: 현재 녹음 선택',
                recordings:
                    widget.recordings
                        .where(
                          (r) =>
                              r.id != _recordingA!.id &&
                              r.createdAt.isAfter(_recordingA!.createdAt),
                        )
                        .toList(),
                selected: _recordingB,
                onSelect: _selectB,
              ),
              _ => _buildComparisonView(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return const BottomSheetHandle();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  () => setState(() {
                    _step = _step - 1;
                    if (_step < 2) _stopAll();
                  }),
            ),
          Icon(Icons.compare_arrows, color: AppColors.primary),
          const SizedBox(width: AppSpacing.space2),
          Text('녹음 비교', style: AppTypography.headingMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _stopAll();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectStep({
    required String label,
    required List<PracticeRecording> recordings,
    required PracticeRecording? selected,
    required ValueChanged<PracticeRecording> onSelect,
  }) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        Text(
          label,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space4),
        ...recordings.map((rec) {
          final isSelected = selected?.id == rec.id;
          final dateLabel = formatDateYMDWithDay(rec.createdAt);
          final timeLabel =
              '${rec.createdAt.hour.toString().padLeft(2, '0')}:${rec.createdAt.minute.toString().padLeft(2, '0')}';
          return InkWell(
            onTap: () => onSelect(rec),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              margin: const EdgeInsets.only(bottom: AppSpacing.space2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Text(
                      '$dateLabel $timeLabel',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Text(
                    rec.formattedDuration,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (rec.bpm != null) ...[
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      rec.bpmText ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildComparisonView() {
    final comparison = RecordingComparison(
      recordingA: _recordingA!,
      recordingB: _recordingB!,
    );
    final dateA =
        '${_recordingA!.createdAt.month}/${_recordingA!.createdAt.day}';
    final dateB =
        '${_recordingB!.createdAt.month}/${_recordingB!.createdAt.day}';

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // Mode toggle: sequential vs parallel
        _buildModeToggle(),
        const SizedBox(height: AppSpacing.space4),

        if (_parallelMode) ...[
          // Parallel waveform view (Phase 2)
          _buildParallelWaveformView(dateA, dateB),
        ] else ...[
          // Sequential player cards (Phase 1)
          _buildPlayerCard(
            label: 'A ($dateA)',
            recording: _recordingA!,
            isPlaying: _playingA,
            position: _positionA,
            duration: _durationA,
            onPlay: _playA,
            onStop: () => _playerA.stop(),
          ),
          const SizedBox(height: AppSpacing.space4),
          _buildPlayerCard(
            label: 'B ($dateB)',
            recording: _recordingB!,
            isPlaying: _playingB,
            position: _positionB,
            duration: _durationB,
            onPlay: _playB,
            onStop: () => _playerB.stop(),
          ),
        ],

        const SizedBox(height: AppSpacing.space6),

        // Comparison summary
        _buildSummaryCard(comparison),

        const SizedBox(height: AppSpacing.space4),

        // Speed control (Phase 2)
        _buildSpeedControl(),

        const SizedBox(height: AppSpacing.space3),

        // Alternate listen toggle (sequential mode only)
        if (!_parallelMode)
          Center(
            child: FilterChip(
              label: Text(
                '번갈아 듣기',
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      _alternateMode
                          ? Colors.white
                          : AppColors.textPrimaryLight,
                ),
              ),
              selected: _alternateMode,
              selectedColor: AppColors.primary,
              avatar: Icon(
                Icons.repeat,
                size: 18,
                color:
                    _alternateMode
                        ? Colors.white
                        : AppColors.textSecondaryLight,
              ),
              onSelected: (v) => setState(() => _alternateMode = v),
            ),
          ),
      ],
    );
  }

  /// Toggle between sequential and parallel mode.
  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildModeChip(
            icon: Icons.swap_vert,
            label: '순차 재생',
            isSelected: !_parallelMode,
            onTap: () {
              _stopAll();
              setState(() => _parallelMode = false);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: _buildModeChip(
            icon: Icons.vertical_split,
            label: '병렬 파형',
            isSelected: _parallelMode,
            onTap: () {
              _stopAll();
              setState(() {
                _parallelMode = true;
                _alternateMode = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space1),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color:
                    isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parallel waveform comparison (Phase 2).
  Widget _buildParallelWaveformView(String dateA, String dateB) {
    final progressA =
        _durationA.inMilliseconds > 0
            ? _positionA.inMilliseconds / _durationA.inMilliseconds
            : 0.0;
    final progressB =
        _durationB.inMilliseconds > 0
            ? _positionB.inMilliseconds / _durationB.inMilliseconds
            : 0.0;

    return Column(
      children: [
        // Waveform A
        _buildWaveformCard(
          label: 'A ($dateA)',
          isPlaying: _playingA,
          progress: progressA,
          duration: _durationA,
          position: _positionA,
          bpmText: _recordingA!.bpmText,
          onSeek:
              (p) => _playerA.seek(
                Duration(milliseconds: (p * _durationA.inMilliseconds).round()),
              ),
        ),
        const SizedBox(height: AppSpacing.space3),
        // Waveform B
        _buildWaveformCard(
          label: 'B ($dateB)',
          isPlaying: _playingB,
          progress: progressB,
          duration: _durationB,
          position: _positionB,
          bpmText: _recordingB!.bpmText,
          onSeek:
              (p) => _playerB.seek(
                Duration(milliseconds: (p * _durationB.inMilliseconds).round()),
              ),
        ),
        const SizedBox(height: AppSpacing.space4),
        // Sync play/stop controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _playSynced,
              icon: Icon(
                _playingA || _playingB ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                _playingA || _playingB ? '정지' : '동시 재생',
                style: AppTypography.buttonSmall.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformCard({
    required String label,
    required bool isPlaying,
    required double progress,
    required Duration duration,
    required Duration position,
    required String? bpmText,
    required ValueChanged<double> onSeek,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isPlaying ? AppColors.primary : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              if (bpmText != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  bpmText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ZoomableWaveformProgressBar(
            progress: progress.clamp(0.0, 1.0),
            duration: duration,
            onSeek: onSeek,
            height: 50,
          ),
        ],
      ),
    );
  }

  /// Synchronized playback: play both A and B simultaneously.
  Future<void> _playSynced() async {
    if (_playingA || _playingB) {
      await _stopAll();
      return;
    }
    await _playerA.setPlaybackRate(_playbackRate);
    await _playerB.setPlaybackRate(_playbackRate);
    await _playerA.play(DeviceFileSource(_recordingA!.filePath));
    await _playerB.play(DeviceFileSource(_recordingB!.filePath));
  }

  /// Speed control widget.
  Widget _buildSpeedControl() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.speed, size: 16, color: AppColors.textTertiaryLight),
        const SizedBox(width: AppSpacing.space2),
        ...speeds.map((speed) {
          final isSelected = (_playbackRate - speed).abs() < 0.01;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () async {
                setState(() => _playbackRate = speed);
                await _playerA.setPlaybackRate(speed);
                await _playerB.setPlaybackRate(speed);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  '${speed}x',
                  style: AppTypography.caption.copyWith(
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String label,
    required PracticeRecording recording,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required VoidCallback onPlay,
    required VoidCallback onStop,
  }) {
    final progress =
        duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isPlaying ? AppColors.primary : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: isPlaying ? onStop : onPlay,
                color: AppColors.primary,
              ),
              Text(
                '${_formatDuration(position)} / ${recording.formattedDuration}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              if (recording.bpm != null)
                Text(
                  recording.bpmText ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(RecordingComparison comparison) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '변화',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          if (comparison.bpmDelta != null) ...[
            _buildSummaryRow(
              icon: Icons.music_note,
              label: 'BPM',
              value:
                  '${comparison.recordingA.bpm} → ${comparison.recordingB.bpm}',
              delta:
                  '${comparison.bpmDelta! > 0 ? "+" : ""}${comparison.bpmDelta}',
              isPositive: comparison.bpmDelta! > 0,
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          _buildSummaryRow(
            icon: Icons.timer_outlined,
            label: '시간',
            value:
                '${comparison.recordingA.formattedDuration} → ${comparison.recordingB.formattedDuration}',
            delta:
                '${comparison.durationDelta > 0 ? "+" : ""}${comparison.durationDelta}초',
            isPositive: null,
          ),
          const SizedBox(height: AppSpacing.space2),
          _buildSummaryRow(
            icon: Icons.calendar_today,
            label: '기간',
            value: '${comparison.daysBetween}일',
            delta: null,
            isPositive: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    String? delta,
    bool? isPositive,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: AppSpacing.space2),
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(value, style: AppTypography.bodyMedium),
        if (delta != null) ...[
          const SizedBox(width: AppSpacing.space2),
          Text(
            delta,
            style: AppTypography.bodySmall.copyWith(
              color:
                  isPositive == true
                      ? AppColors.success
                      : isPositive == false
                      ? AppColors.error
                      : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
