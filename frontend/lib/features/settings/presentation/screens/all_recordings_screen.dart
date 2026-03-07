// Screen for viewing and managing all recordings with their section connections.
//
// Allows users to:
// - View all recordings with their connected section info
// - Change the section a recording is connected to
// - Delete recordings
// - Play recordings using the shared RecordingPlayerSheet
// - Import recordings from device files

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../models/recording.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../practice/domain/entities/practice_repertoire.dart';
import '../../../practice/presentation/screens/section_picker_screen.dart';
import '../../../practice/presentation/widgets/recording_player_sheet.dart';
import '../providers/orphan_recording_provider.dart';

/// Screen for managing all recordings.
class AllRecordingsScreen extends ConsumerWidget {
  const AllRecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(allRecordingsWithSectionInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('전체 녹음 파일'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _importRecording(context, ref),
            tooltip: '녹음 가져오기',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allRecordingsWithSectionInfoProvider);
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allRecordingsWithSectionInfoProvider);
        },
        child: recordingsAsync.when(
          data: (recordings) => recordings.isEmpty
              ? _buildEmptyState()
              : _RecordingsList(recordings: recordings),
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
                  onPressed: () => ref.invalidate(allRecordingsWithSectionInfoProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importRecording(BuildContext context, WidgetRef ref) async {
    // Pick audio file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'wav', 'aac', 'flac'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일을 읽을 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Get audio duration using just_audio
      final audioPlayer = AudioPlayer();
      final duration = await audioPlayer.setFilePath(file.path!);
      await audioPlayer.dispose();

      final durationSeconds = duration?.inSeconds ?? 0;

      // Import the recording
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .importRecording(file.path!, durationSeconds);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('녹음 파일을 가져왔습니다: ${file.name}'),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일 가져오기 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_none,
                size: 64,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 16),
              const Text(
                '녹음 파일이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordingsList extends StatelessWidget {
  final List<({PracticeRecording recording, PracticeSection? section, PracticeRepertoire? repertoire})> recordings;

  const _RecordingsList({required this.recordings});

  @override
  Widget build(BuildContext context) {
    final connected = recordings.where((r) => r.section != null).toList();
    final orphaned = recordings.where((r) => r.section == null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        _buildStatsCard(connected.length, orphaned.length),
        const SizedBox(height: 16),

        // Orphaned recordings section (show first if any)
        if (orphaned.isNotEmpty) ...[
          _buildSectionHeader('연결되지 않은 녹음', orphaned.length, AppColors.warning),
          ...orphaned.map((r) => _RecordingCard(
            recording: r.recording,
            section: null,
            repertoire: null,
          )),
          const SizedBox(height: 16),
        ],

        // Connected recordings section
        if (connected.isNotEmpty) ...[
          _buildSectionHeader('연결된 녹음', connected.length, AppColors.primary),
          ...connected.map((r) => _RecordingCard(
            recording: r.recording,
            section: r.section,
            repertoire: r.repertoire,
          )),
        ],
      ],
    );
  }

  Widget _buildStatsCard(int connectedCount, int orphanedCount) {
    final total = connectedCount + orphanedCount;
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('전체', total, AppColors.textPrimaryLight),
            _buildStatItem('연결됨', connectedCount, AppColors.success),
            _buildStatItem('미연결', orphanedCount, AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count개',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends ConsumerWidget {
  final PracticeRecording recording;
  final PracticeSection? section;
  final PracticeRepertoire? repertoire;

  const _RecordingCard({
    required this.recording,
    this.section,
    this.repertoire,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _playRecording(BuildContext context, WidgetRef ref) {
    final studentId = ref.read(currentUserIdProvider);
    final repertoireId = repertoire?.id ?? 'unknown';

    // Convert PracticeRecording to Recording model for the player sheet
    final recordingModel = Recording(
      id: recording.id,
      repertoireId: repertoireId,
      studentId: studentId,
      type: RecordingType.student,
      localPath: recording.filePath,
      durationSeconds: recording.durationSeconds,
      recordedAt: recording.createdAt,
      isRepresentative: recording.isRepresentative,
    );

    // Show the recording player bottom sheet (handles metadata/smart recording automatically)
    RecordingPlayerSheet.show(
      context,
      recording: recordingModel,
      repertoireId: repertoireId,
      studentId: studentId,
    );
  }

  Future<void> _showSectionPicker(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<SectionPickerResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SectionPickerScreen(
          title: '녹음을 연결할 섹션 선택',
          recording: recording,
        ),
      ),
    );

    if (result != null && context.mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .reassignRecording(recording.id, result.section.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('녹음이 "${result.section.pieceName}"에 연결되었습니다'),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('연결 중 오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .deleteRecording(recording.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음이 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final isOrphaned = section == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOrphaned ? AppColors.warning : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Play button
            IconButton(
              onPressed: () => _playRecording(context, ref),
              icon: const Icon(
                Icons.play_circle_filled,
                size: 32,
                color: AppColors.primary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 8),
            // Date and section info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Repertoire > Section name (or "연결되지 않음")
                  if (repertoire != null && section != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 12,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${repertoire!.name} > ${section!.pieceName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '연결되지 않음',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Date and duration
                  Row(
                    children: [
                      Text(
                        dateFormat.format(recording.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(recording.durationSeconds),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      if (recording.bpm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${recording.bpm}bpm',
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
            // Link button (link icon for connected, link_off for orphaned)
            IconButton(
              onPressed: () => _showSectionPicker(context, ref),
              icon: Icon(isOrphaned ? Icons.link_off : Icons.link),
              color: isOrphaned ? AppColors.warning : AppColors.primary,
              tooltip: isOrphaned ? '섹션에 연결' : '섹션 변경',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Delete button
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              tooltip: '삭제',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }
}
