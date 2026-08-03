import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../providers/practice_scratch_mode_storage_provider.dart';
import 'scratch_stamp_sheet.dart';
import 'stamp_template.dart';

/// Shared gesture layer for the N회 반복 practice-stamp interaction.
///
/// Wraps a purely visual [child] (a paw-stamp row) and owns the
/// tap-to-scratch / long-press-to-reset behavior so both call sites
/// (repertoire list row, section detail toggle card) share one
/// implementation. The actual data mutation stays with [onIncrement] — this
/// widget never touches `PracticeSection` directly (data model unchanged,
/// pure interaction layer).
///
/// - Tap on a not-yet-filled row: opens [ScratchStampSheet] (unless the
///   student has enabled quick-check mode, in which case it increments
///   immediately). On success, calls [onIncrement] exactly once.
/// - Long-press on a fully-filled row: confirms via [showNotebookDialog]
///   before calling [onIncrement] again, which reuses the existing
///   provider-level cycle-to-zero behavior (there is no per-unit decrement
///   primitive in the repository layer).
class PracticeStampGesture extends ConsumerStatefulWidget {
  final String studentId;
  final int completedCount;
  final int totalCount;
  final VoidCallback onIncrement;
  final Widget child;
  final StampTemplate template;

  const PracticeStampGesture({
    super.key,
    required this.studentId,
    required this.completedCount,
    required this.totalCount,
    required this.onIncrement,
    required this.child,
    this.template = StampTemplate.catPaw,
  });

  @override
  ConsumerState<PracticeStampGesture> createState() =>
      _PracticeStampGestureState();
}

class _PracticeStampGestureState extends ConsumerState<PracticeStampGesture> {
  bool _busy = false;

  bool get _isFilled => widget.completedCount >= widget.totalCount;

  Future<void> _handleTap() async {
    if (_busy || _isFilled) return;
    _busy = true;
    try {
      final quickMode = await ref.read(
        practiceScratchModeStorageProvider(widget.studentId).future,
      );
      if (!mounted) return;
      if (quickMode) {
        widget.onIncrement();
        return;
      }
      final completed = await ScratchStampSheet.show(
        context: context,
        studentId: widget.studentId,
        completedCount: widget.completedCount,
        totalCount: widget.totalCount,
        template: widget.template,
      );
      if (completed == true) {
        widget.onIncrement();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleLongPress() async {
    if (_busy || !_isFilled) return;
    _busy = true;
    try {
      final confirmed = await showNotebookDialog<bool>(
        context: context,
        title: AppStrings.practiceStampResetConfirmTitle,
        message: AppStrings.practiceStampResetConfirmMessage,
        cancelLabel: AppStrings.cancel,
        confirmLabel: AppStrings.confirm,
        isDestructive: true,
      );
      if (confirmed == true) {
        widget.onIncrement();
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: widget.child,
    );
  }
}
