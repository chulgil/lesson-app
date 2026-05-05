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
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/practice/domain/entities/recording.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../practice/domain/entities/practice_repertoire.dart';
import '../../../practice/practice_ui_facade.dart';
import '../providers/orphan_recording_provider.dart';

/// Screen for managing all recordings.
class AllRecordingsScreen extends ConsumerWidget {
  const AllRecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingsAsync = ref.watch(allRecordingsWithSectionInfoProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text(AppStrings.allRecordingsAppBarTitle),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        foregroundColor: AppColors.ink,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _importRecording(context, ref),
            tooltip: AppStrings.allRecordingsImportTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allRecordingsWithSectionInfoProvider);
            },
            tooltip: AppStrings.refreshTooltip,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allRecordingsWithSectionInfoProvider);
        },
        child: recordingsAsync.when(
          data:
              (recordings) =>
                  recordings.isEmpty
                      ? _buildEmptyState()
                      : _RecordingsList(recordings: recordings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.paperAccent,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    const Text(
                      AppStrings.allRecordingsErrorState,
                      style: TextStyle(color: AppColors.paperAccent),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    ElevatedButton(
                      onPressed:
                          () => ref.invalidate(
                            allRecordingsWithSectionInfoProvider,
                          ),
                      child: const Text(AppStrings.retry),
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
            content: Text(AppStrings.allRecordingsFileReadError),
            backgroundColor: AppColors.paperAccent,
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
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
            content: Text(AppStrings.allRecordingsImportedFormat(file.name)),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.allRecordingsImportError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorOccurredRetryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.mic_none,
      title: AppStrings.recordingsEmpty,
      scrollable: true,
    );
  }
}

class _RecordingsList extends StatelessWidget {
  final List<
    ({
      PracticeRecording recording,
      PracticeSection? section,
      PracticeRepertoire? repertoire,
    })
  >
  recordings;

  const _RecordingsList({required this.recordings});

  @override
  Widget build(BuildContext context) {
    final connected = recordings.where((r) => r.section != null).toList();
    final orphaned = recordings.where((r) => r.section == null).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // Stats card
        _buildStatsCard(connected.length, orphaned.length),
        const SizedBox(height: AppSpacing.space4),

        // Orphaned recordings section (show first if any)
        if (orphaned.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.allRecordingsOrphanedSection,
            orphaned.length,
            AppColors.paperAccent,
          ),
          ...orphaned.map(
            (r) => _RecordingCard(
              recording: r.recording,
              section: null,
              repertoire: null,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Connected recordings section
        if (connected.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.allRecordingsConnectedSection,
            connected.length,
            AppColors.paperAccent,
          ),
          ...connected.map(
            (r) => _RecordingCard(
              recording: r.recording,
              section: r.section,
              repertoire: r.repertoire,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsCard(int connectedCount, int orphanedCount) {
    final total = connectedCount + orphanedCount;
    return NotebookCard(
      elevation: 0,
      color: AppColors.paperAccentSoft,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.paperAccentSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(AppStrings.all, total, AppColors.ink),
            _buildStatItem(
              AppStrings.allRecordingsConnectedStatLabel,
              connectedCount,
              AppColors.paperOk,
            ),
            _buildStatItem(
              AppStrings.allRecordingsOrphanedStatLabel,
              orphanedCount,
              AppColors.paperAccent,
            ),
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
          style: AppTypography.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(color: color),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: 2,
            ),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
            child: Text(
              '$count개',
              style: AppTypography.bodySmall.copyWith(
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
        builder:
            (context) => SectionPickerScreen(
              title: AppStrings.allRecordingsSectionPickerTitle,
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
            content: Text(
              AppStrings.allRecordingsLinkedFormat(result.section.pieceName),
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.allRecordingsLinkError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.allRecordingsDeleteDialogTitle,
      content: const Text(AppStrings.allRecordingsDeleteDialogContent),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .deleteRecording(recording.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.allRecordingsDeletedSnack)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrphaned = section == null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: isOrphaned ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        child: Row(
          children: [
            // Play button
            IconButton(
              onPressed: () => _playRecording(context, ref),
              icon: const Icon(
                Icons.play_circle_filled,
                size: 32,
                color: AppColors.paperAccent,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: AppSpacing.space2),
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
                          color: AppColors.paperAccent,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Expanded(
                          child: Text(
                            '${repertoire!.name} > ${section!.pieceName}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.paperAccent,
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
                          color: AppColors.paperAccent,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          AppStrings.allRecordingsOrphanedInline,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.paperAccent,
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
                        formatDateTimeDotPadded(recording.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        _formatDuration(recording.durationSeconds),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      if (recording.bpm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${recording.bpm}bpm',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperAccent,
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
              color: isOrphaned ? AppColors.paperAccent : AppColors.paperAccent,
              tooltip:
                  isOrphaned
                      ? AppStrings.allRecordingsLinkSectionTooltip
                      : AppStrings.allRecordingsChangeSectionTooltip,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Delete button
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.paperAccent,
              tooltip: AppStrings.delete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }
}
