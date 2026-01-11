// Screen for managing orphaned recordings (recordings not linked to any section).
//
// Allows users to reassign orphaned recordings to existing sections or delete them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../practice/domain/entities/practice_repertoire.dart';
import '../../../practice/presentation/screens/section_picker_screen.dart';
import '../providers/orphan_recording_provider.dart';

/// Screen for managing orphaned recordings.
class OrphanRecordingsScreen extends ConsumerWidget {
  const OrphanRecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticAsync = ref.watch(orphanedRecordingsWithDiagnosticProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('연결되지 않은 녹음'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(orphanRecordingManagerProvider.notifier).refreshFromHive();
              ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
            },
            tooltip: '새로고침 (경로 복구 포함)',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(orphanRecordingManagerProvider.notifier).refreshFromHive();
          ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
        },
        child: diagnosticAsync.when(
          data: (diagnostic) => diagnostic.orphans.isEmpty
              ? _EmptyStateWithDiagnostic(diagnostic: diagnostic)
              : _RecordingsListWithDiagnostic(diagnostic: diagnostic),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('오류: $e', style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(orphanedRecordingsWithDiagnosticProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWithDiagnostic extends StatelessWidget {
  final OrphanRecordingsDiagnostic diagnostic;

  const _EmptyStateWithDiagnostic({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Diagnostic card at top
        _DiagnosticCard(diagnostic: diagnostic),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '연결되지 않은 녹음이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '모든 녹음이 섹션에 연결되어 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '아래로 당겨서 새로고침 (경로 복구 포함)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final OrphanRecordingsDiagnostic diagnostic;

  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '진단 정보',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Hive에 저장된 녹음', '${diagnostic.totalRecordingsInHive}개'),
            _buildStatRow('섹션 수', '${diagnostic.totalSections}개'),
            _buildStatRow('연결되지 않은 녹음', '${diagnostic.orphanCount}개'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingsListWithDiagnostic extends ConsumerWidget {
  final OrphanRecordingsDiagnostic diagnostic;

  const _RecordingsListWithDiagnostic({required this.diagnostic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diagnostic.orphans.length + 2, // +2 for diagnostic card and header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _DiagnosticCard(diagnostic: diagnostic),
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${diagnostic.orphans.length}개의 녹음이 섹션에 연결되지 않았습니다.\n각 녹음을 섹션에 연결하거나 삭제할 수 있습니다.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
          );
        }
        return _RecordingCard(recording: diagnostic.orphans[index - 2]);
      },
    );
  }
}

class _RecordingCard extends ConsumerStatefulWidget {
  final PracticeRecording recording;

  const _RecordingCard({required this.recording});

  @override
  ConsumerState<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends ConsumerState<_RecordingCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setFilePath(widget.recording.filePath);
      _duration = _audioPlayer.duration ?? Duration.zero;

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to init audio player: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _showAssignmentSheet() async {
    final result = await Navigator.push<SectionPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SectionPickerScreen(
          title: '녹음을 연결할 섹션 선택',
          recording: widget.recording,
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .reassignRecording(widget.recording.id, result.section.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('녹음이 "${result.section.pieceName}"에 연결되었습니다'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('연결 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('녹음 삭제'),
        content: const Text('이 녹음을 영구적으로 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .deleteRecording(widget.recording.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음이 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact row: play | date | duration | bpm | link | delete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Play button (smaller)
                IconButton(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                const SizedBox(width: 8),
                // Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateFormat.format(widget.recording.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          if (widget.recording.bpm != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${widget.recording.bpm}bpm',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Link button (connect to section)
                IconButton(
                  onPressed: _showAssignmentSheet,
                  icon: const Icon(Icons.link),
                  color: AppColors.primary,
                  tooltip: '섹션에 연결',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                // Delete button
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  tooltip: '삭제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          // Progress bar (when playing)
          if (_isPlaying || _position.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: LinearProgressIndicator(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}

