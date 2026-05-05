// Screen for managing orphaned recordings (recordings not linked to any section).
//
// Allows users to reassign orphaned recordings to existing sections or delete them.

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
import '../../../practice/domain/entities/practice_repertoire.dart';
import '../../../practice/practice_ui_facade.dart';
import '../providers/orphan_recording_provider.dart';

/// Screen for managing orphaned recordings.
class OrphanRecordingsScreen extends ConsumerWidget {
  const OrphanRecordingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticAsync = ref.watch(orphanedRecordingsWithDiagnosticProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text(AppStrings.allRecordingsOrphanedSection),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        foregroundColor: AppColors.ink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref
                  .read(orphanRecordingManagerProvider.notifier)
                  .refreshFromHive();
              ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
            },
            tooltip: AppStrings.orphanRecordingsRefreshTooltip,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(orphanRecordingManagerProvider.notifier)
              .refreshFromHive();
          ref.invalidate(orphanedRecordingsWithDiagnosticProvider);
        },
        child: diagnosticAsync.when(
          data:
              (diagnostic) =>
                  diagnostic.orphans.isEmpty
                      ? _EmptyStateWithDiagnostic(diagnostic: diagnostic)
                      : _RecordingsListWithDiagnostic(diagnostic: diagnostic),
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
                            orphanedRecordingsWithDiagnosticProvider,
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
}

class _EmptyStateWithDiagnostic extends StatelessWidget {
  final OrphanRecordingsDiagnostic diagnostic;

  const _EmptyStateWithDiagnostic({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // Diagnostic card at top
        _DiagnosticCard(diagnostic: diagnostic),
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        const EmptyStateWidget(
          icon: Icons.check_circle_outline,
          title: AppStrings.orphanRecordingsEmptyTitle,
          subtitle: AppStrings.orphanRecordingsEmptySubtitle,
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
    return NotebookCard(
      elevation: 0,
      color: AppColors.paperAccentSoft,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.paperAccentSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(width: AppSpacing.space2),
                const Text(
                  AppStrings.orphanRecordingsDiagnosticTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.paperAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildStatRow(
              AppStrings.orphanRecordingsHiveCountLabel,
              AppStrings.countItemsSuffix(diagnostic.totalRecordingsInHive),
            ),
            _buildStatRow(
              AppStrings.orphanRecordingsSectionCountLabel,
              AppStrings.countItemsSuffix(diagnostic.totalSections),
            ),
            _buildStatRow(
              AppStrings.allRecordingsOrphanedSection,
              AppStrings.countItemsSuffix(diagnostic.orphanCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
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
      padding: const EdgeInsets.all(AppSpacing.space4),
      itemCount:
          diagnostic.orphans.length + 2, // +2 for diagnostic card and header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space4),
            child: _DiagnosticCard(diagnostic: diagnostic),
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space4),
            child: Text(
              AppStrings.orphanRecordingsDescriptionFormat(
                diagnostic.orphans.length,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
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
      // Audio player init failed, ignore
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
        builder:
            (context) => SectionPickerScreen(
              title: AppStrings.allRecordingsSectionPickerTitle,
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
            content: Text(
              AppStrings.allRecordingsLinkedFormat(result.section.pieceName),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.allRecordingsLinkError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
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

    if (confirmed == true && mounted) {
      final success = await ref
          .read(orphanRecordingManagerProvider.notifier)
          .deleteRecording(widget.recording.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.allRecordingsDeletedSnack)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact row: play | date | duration | bpm | link | delete
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            child: Row(
              children: [
                // Play button (smaller)
                IconButton(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 32,
                    color: AppColors.paperAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                // Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDateTimeDotPadded(widget.recording.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDuration(_duration),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          if (widget.recording.bpm != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${widget.recording.bpm}bpm',
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
                // Link button (connect to section)
                IconButton(
                  onPressed: _showAssignmentSheet,
                  icon: const Icon(Icons.link),
                  color: AppColors.paperAccent,
                  tooltip: AppStrings.allRecordingsLinkSectionTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.paperAccent,
                  tooltip: AppStrings.delete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar (when playing)
          if (_isPlaying || _position.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space2,
                0,
                AppSpacing.space2,
                AppSpacing.space2,
              ),
              child: LinearProgressIndicator(
                value:
                    _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                backgroundColor: AppColors.inkQuaternary,
                valueColor: const AlwaysStoppedAnimation(AppColors.paperAccent),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }
}
