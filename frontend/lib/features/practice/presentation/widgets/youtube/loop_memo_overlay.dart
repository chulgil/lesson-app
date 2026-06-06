import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../domain/entities/loop_memo.dart';

/// Display + author affordance for the student-authored loop memos pinned to a
/// [PracticeLoopOverride]. Renders:
///
/// - A small "+ 메모" button anchored to the corner.
/// - A short paper-card overlay that surfaces when [currentPositionSeconds] is
///   within [visibilityWindowSeconds] of a memo's `atSeconds`. Only one memo
///   is visible at a time to avoid covering the video.
///
/// Spec: GH #510 — Loop Memo (§3.5 follow-up).
// ignore: widget-smoke-test
class LoopMemoOverlay extends StatefulWidget {
  final List<LoopMemo> memos;
  final int currentPositionSeconds;
  final Future<void> Function(String text)? onAdd;
  final Future<void> Function(LoopMemo memo, String text)? onEdit;
  final Future<void> Function(LoopMemo memo)? onDelete;

  /// How long (seconds) a memo stays visible after its `atSeconds` tick.
  static const visibilityWindowSeconds = 3;

  /// Hard cap on memo length enforced by the input modal.
  static const maxMemoLength = 100;

  const LoopMemoOverlay({
    super.key,
    required this.memos,
    required this.currentPositionSeconds,
    this.onAdd,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<LoopMemoOverlay> createState() => _LoopMemoOverlayState();
}

class _LoopMemoOverlayState extends State<LoopMemoOverlay> {
  /// The memo currently being surfaced (if any).
  LoopMemo? _activeMemo;

  @override
  void didUpdateWidget(covariant LoopMemoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeActive();
  }

  @override
  void initState() {
    super.initState();
    _recomputeActive();
  }

  void _recomputeActive() {
    final memo = _findActiveMemo();
    if (memo != _activeMemo) {
      // Schedule after build to keep this widget pure during didUpdateWidget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _activeMemo = memo);
      });
    }
  }

  LoopMemo? _findActiveMemo() {
    for (final memo in widget.memos) {
      final delta = widget.currentPositionSeconds - memo.atSeconds;
      if (delta >= 0 && delta < LoopMemoOverlay.visibilityWindowSeconds) {
        return memo;
      }
    }
    return null;
  }

  Future<void> _openAddSheet() async {
    final onAdd = widget.onAdd;
    if (onAdd == null) return;
    final text = await _showEditor(initialText: '');
    if (text != null && text.isNotEmpty) {
      await onAdd(text);
    }
  }

  Future<void> _openEditSheet(LoopMemo memo) async {
    final onEdit = widget.onEdit;
    if (onEdit == null) return;
    final text = await _showEditor(initialText: memo.text);
    if (text != null && text.isNotEmpty) {
      await onEdit(memo, text);
    }
  }

  Future<void> _confirmDelete(LoopMemo memo) async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => NotebookAlertDialog(
            content: const Text(
              AppStrings.loopMemoDeleteConfirm,
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(AppStrings.loopMemoCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                ),
                child: const Text(AppStrings.loopMemoDelete),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await onDelete(memo);
    }
  }

  Future<String?> _showEditor({required String initialText}) async {
    final controller = TextEditingController(text: initialText);
    final result = await showNotebookModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(color: AppColors.paper),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: LoopMemoOverlay.maxMemoLength,
                  maxLines: 2,
                  style: NotebookTypography.hand,
                  decoration: const InputDecoration(
                    hintText: AppStrings.loopMemoAddHint,
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.loopMemoMaxLength,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(AppStrings.loopMemoCancel),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    FilledButton(
                      onPressed:
                          () => Navigator.of(ctx).pop(controller.text.trim()),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          AppSpacing.buttonHeightSmall,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        backgroundColor: AppColors.paperAccent,
                      ),
                      child: const Text(AppStrings.loopMemoSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    // Defer dispose to the next frame so the sheet's teardown can still
    // safely reference the controller before its listeners detach.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final activeMemo = _activeMemo;
    return Stack(
      children: [
        if (activeMemo != null)
          Positioned(
            top: AppSpacing.space2,
            left: AppSpacing.space2,
            right: AppSpacing.space2,
            child: _MemoCard(
              memo: activeMemo,
              onEdit:
                  widget.onEdit == null
                      ? null
                      : () => _openEditSheet(activeMemo),
              onDelete:
                  widget.onDelete == null
                      ? null
                      : () => _confirmDelete(activeMemo),
            ),
          ),
        if (widget.onAdd != null)
          Positioned(
            right: AppSpacing.space2,
            bottom: AppSpacing.space2,
            child: _AddMemoButton(onTap: _openAddSheet),
          ),
      ],
    );
  }
}

class _MemoCard extends StatelessWidget {
  final LoopMemo memo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MemoCard({required this.memo, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper.withValues(alpha: 0.94),
          border: Border.all(color: AppColors.paperAccent, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                memo.text,
                style: NotebookTypography.hand.copyWith(color: AppColors.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: AppSpacing.space2),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDelete,
                child: Text(
                  AppStrings.loopMemoDelete,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddMemoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMemoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: const BoxDecoration(color: AppColors.paperAccent),
        child: Text(
          AppStrings.loopMemoAdd,
          style: AppTypography.bodySmall.copyWith(color: AppColors.paper),
        ),
      ),
    );
  }
}
