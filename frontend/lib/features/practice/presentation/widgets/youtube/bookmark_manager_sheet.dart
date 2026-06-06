import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../domain/entities/loop_bookmark.dart';
import '../../../domain/entities/practice_loop_override.dart';
import '../../extensions/audio_mix_visuals.dart';

/// Bottom sheet for managing multi-marker loop bookmarks (#511).
///
/// Lists existing bookmarks for the current section and exposes add / rename /
/// delete / select actions. The host wires up the loop provider via the
/// callbacks below.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.10
// ignore: widget-smoke-test
class BookmarkManagerSheet extends StatelessWidget {
  final List<LoopBookmark> bookmarks;
  final String? activeBookmarkId;

  /// Suggested name for a newly-created bookmark (UI prefills the editor).
  final String suggestedNewName;

  /// Current A-B range that "추가" should capture. The host passes the live
  /// override / teacher defaults so the student can name what's already set.
  final int currentStartSeconds;
  final int currentEndSeconds;

  final Future<void> Function({
    required String name,
    required int startSeconds,
    required int endSeconds,
  })?
  onAdd;
  final Future<void> Function(LoopBookmark bookmark, String name)? onRename;
  final Future<void> Function(LoopBookmark bookmark)? onDelete;
  final void Function(LoopBookmark bookmark)? onSelect;

  const BookmarkManagerSheet({
    super.key,
    required this.bookmarks,
    required this.activeBookmarkId,
    required this.currentStartSeconds,
    required this.currentEndSeconds,
    this.suggestedNewName = '',
    this.onAdd,
    this.onRename,
    this.onDelete,
    this.onSelect,
  });

  /// Static palette of five tones used for the [colorIndex] slot. Hand-picked
  /// to remain legible on the cream paper background.
  static const List<Color> bookmarkPalette = [
    AppColors.paperAccent,
    AppColors.paperOk,
    AppColors.inkSecondary,
    AppColors.paperTrial,
    AppColors.paperHighlight,
  ];

  static Color colorFor(int colorIndex) =>
      bookmarkPalette[colorIndex % bookmarkPalette.length];

  bool get _limitReached =>
      bookmarks.length >= PracticeLoopOverride.maxBookmarks;

  Future<void> _showEditor(
    BuildContext context, {
    required String initialName,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: initialName);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return NotebookAlertDialog(
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: AppStrings.bookmarkName,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(AppStrings.bookmarkCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                backgroundColor: AppColors.paperAccent,
              ),
              onPressed: () {
                final value = controller.text.trim();
                Navigator.of(dialogCtx).pop();
                onSubmit(value);
              },
              child: const Text(AppStrings.bookmarkSave),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LoopBookmark bookmark,
  ) async {
    final onDelete = this.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            content: const Text(
              AppStrings.bookmarkDeleteConfirm,
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(AppStrings.bookmarkCancel),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(AppStrings.bookmarkDelete),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await onDelete(bookmark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    AppStrings.bookmarkManage,
                    style: AppTypography.headingSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${bookmarks.length} / ${PracticeLoopOverride.maxBookmarks}',
                    style: NotebookTypography.tempoMono.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              if (bookmarks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
                  child: Text(
                    AppStrings.bookmarkEmpty,
                    style: AppTypography.bodyMedium,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bookmarks.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(height: AppSpacing.space2),
                    itemBuilder: (ctx, i) {
                      final bookmark = bookmarks[i];
                      return _BookmarkRow(
                        bookmark: bookmark,
                        active: bookmark.id == activeBookmarkId,
                        onSelect:
                            onSelect == null ? null : () => onSelect!(bookmark),
                        onRename:
                            onRename == null
                                ? null
                                : () => _showEditor(
                                  ctx,
                                  initialName: bookmark.name,
                                  onSubmit: (newName) {
                                    if (newName.isEmpty) return;
                                    onRename!(bookmark, newName);
                                  },
                                ),
                        onDelete:
                            onDelete == null
                                ? null
                                : () => _confirmDelete(ctx, bookmark),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.space3),
              if (_limitReached)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Text(
                    AppStrings.bookmarkLimitReached,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: AppColors.paperAccent,
                ),
                onPressed:
                    (_limitReached || onAdd == null)
                        ? null
                        : () {
                          _showEditor(
                            context,
                            initialName: suggestedNewName,
                            onSubmit: (name) {
                              onAdd!(
                                name: name,
                                startSeconds: currentStartSeconds,
                                endSeconds: currentEndSeconds,
                              );
                            },
                          );
                        },
                child: Text(
                  '${AppStrings.bookmarkAdd}  '
                  '${formatLoopSeconds(currentStartSeconds)}'
                  '–${formatLoopSeconds(currentEndSeconds)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  final LoopBookmark bookmark;
  final bool active;
  final VoidCallback? onSelect;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const _BookmarkRow({
    required this.bookmark,
    required this.active,
    this.onSelect,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = BookmarkManagerSheet.colorFor(bookmark.colorIndex);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.paperAccentSoft : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${formatLoopSeconds(bookmark.startSeconds)} – '
                    '${formatLoopSeconds(bookmark.endSeconds)}',
                    style: NotebookTypography.tempoMono.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onRename != null)
            TextButton(
              onPressed: onRename,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                foregroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.bookmarkName),
            ),
          if (onDelete != null)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
                foregroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.bookmarkDelete),
            ),
        ],
      ),
    );
  }
}
