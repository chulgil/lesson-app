// Section recording list item widget

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/swipe_action_tile.dart';
import '../../../../../features/practice/domain/entities/practice_repertoire.dart';
import 'recording_actions_bottom_sheet.dart';

/// Recording list item for section detail screen
class SectionRecordingListItem extends StatefulWidget {
  final PracticeRecording recording;
  final String sectionId;
  final String repertoireId;
  final VoidCallback onSetRepresentative;
  final VoidCallback onDelete;
  final VoidCallback onPlay;

  const SectionRecordingListItem({
    super.key,
    required this.recording,
    required this.sectionId,
    required this.repertoireId,
    required this.onSetRepresentative,
    required this.onDelete,
    required this.onPlay,
  });

  @override
  State<SectionRecordingListItem> createState() =>
      _SectionRecordingListItemState();
}

class _SectionRecordingListItemState extends State<SectionRecordingListItem> {
  bool? _fileExists;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  @override
  void didUpdateWidget(SectionRecordingListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording.filePath != widget.recording.filePath) {
      _checkFileExists();
    }
  }

  Future<void> _checkFileExists() async {
    final file = File(widget.recording.filePath);
    final exists = await file.exists();
    if (mounted) {
      setState(() {
        _fileExists = exists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while checking
    if (_fileExists == null) {
      return _buildLoadingState();
    }

    // Show file missing state if file doesn't exist
    if (_fileExists == false) {
      return _buildFileMissingState(context);
    }

    return _buildNormalState(context);
  }

  Widget _buildLoadingState() {
    return NotebookCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.paperDark),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '확인 중...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMissingState(BuildContext context) {
    return NotebookCard(
      color: AppColors.paperAccentSoft,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '파일 없음',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.paperAccent,
                        ),
                      ),
                      if (widget.recording.bpm != null) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inkSecondary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Text(
                            '${widget.recording.bpm} BPM',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(widget.recording.createdAt)} · ${widget.recording.formattedDuration}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '녹음 파일이 삭제되었거나 찾을 수 없습니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],
              ),
            ),
            // Delete button for orphaned recording
            IconButton(
              onPressed: () => _showDeleteConfirmation(context),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.paperAccent,
              tooltip: '기록 삭제',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.practiceRecordingRecordDeleteTitle),
      content: const Text(
        '이 녹음 기록을 삭제하시겠습니까?\n'
        '(파일이 이미 없으므로 기록만 삭제됩니다)',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDelete();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
          child: const Text(AppStrings.delete),
        ),
      ],
    );
  }

  Widget _buildNormalState(BuildContext context) {
    // Swipe consistency (audit 2026-06-10 §2):
    // - 원칙 1: swipe 는 destructive 단일 액션 ([삭제])
    // - 원칙 2: 다중 액션은 행 탭 → BottomSheet 로 분리
    // - 원칙 3: destructive 는 확인 다이얼로그 강제
    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionDelete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmRecordingDelete(context),
        ),
      ],
      child: NotebookCard(
        child: InkWell(
          onTap: () => _openActionsSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space3),
            child: Row(
              children: [
                // 재생은 별도 컨트롤로 유지 (기존 onPlay) — 행 탭은 액션 시트로 변경.
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPlay,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: AppColors.paperAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.recording.formattedDuration,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.recording.bpm != null) ...[
                            const SizedBox(width: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paperAccentSoft,
                              ),
                              child: Text(
                                '${widget.recording.bpm} BPM',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.paperAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (widget.recording.isRepresentative) ...[
                            const SizedBox(width: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paperOk,
                              ),
                              child: Text(
                                '대표',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.paper,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(widget.recording.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openActionsSheet(BuildContext context) async {
    final result = await RecordingActionsBottomSheet.show(
      context,
      canSetRepresentative: !widget.recording.isRepresentative,
    );
    if (!context.mounted) return;
    switch (result) {
      case RecordingActionResult.setRepresentative:
        widget.onSetRepresentative();
      case RecordingActionResult.share:
        await _shareToExternal(context, widget.recording.filePath);
      case RecordingActionResult.delete:
        await _confirmRecordingDelete(context);
      case null:
        break;
    }
  }

  Future<void> _confirmRecordingDelete(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.practiceRecordingDeleteTitle,
      content: const Text(AppStrings.practiceRecordingDeleteConfirm),
      confirmLabel: AppStrings.swipeActionDelete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
    if (confirmed == true) {
      widget.onDelete();
    }
  }

  Future<void> _shareToExternal(BuildContext context, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.practiceRecordingFileNotFound),
          ),
        );
      }
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
