import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../providers/practice_scratch_mode_storage_provider.dart';
import 'scratch_stamp_painter.dart';
import 'stamp_template.dart';

/// Coverage ratio (0.0-1.0) of scratched grid cells (within the stamp
/// shape) required to consider the stamp "완성".
const double _kCompletionThreshold = 0.85;

/// Square size of the scratch canvas (logical px).
const double _kCanvasSize = 220;

/// Grid resolution used for coverage estimation (10x10 = 100 cells).
/// Coverage is estimated by sampling which grid cells the drag points have
/// touched — no per-frame pixel/framebuffer readback.
const int _kGridSize = 10;

/// Radius (logical px) around each dragged point considered "scratched" —
/// used both for the visual erase-mask stroke path and the coverage grid.
const double _kStrokeRadius = 16;

/// Key on the scratch canvas gesture area, used by widget tests to compute
/// drag coordinates.
const scratchStampCanvasKey = Key('scratchStampCanvas');

/// Popup shown when a student taps an empty practice-repeat slot.
///
/// The student rubs (drags a finger) across a stamp template to reveal it —
/// mirroring a paper practice notebook where kids color in a circle per
/// rep. On completion (coverage threshold reached, or long-press instant
/// fill) this pops `true`. Callers are responsible for the actual data
/// mutation (see `PracticeStampGesture`) — this widget never touches
/// `PracticeSection` (data model unchanged, pure interaction layer).
class ScratchStampSheet extends ConsumerStatefulWidget {
  final String studentId;
  final int completedCount;
  final int totalCount;
  final StampTemplate template;

  const ScratchStampSheet({
    super.key,
    required this.studentId,
    required this.completedCount,
    required this.totalCount,
    this.template = StampTemplate.catPaw,
  });

  /// Presents the sheet modally. Returns `true` when the stamp was
  /// completed (scratched past threshold, or long-press instant-filled),
  /// `null` when dismissed without completing.
  static Future<bool?> show({
    required BuildContext context,
    required String studentId,
    required int completedCount,
    required int totalCount,
    StampTemplate template = StampTemplate.catPaw,
  }) {
    return showNotebookModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScratchStampSheet(
        studentId: studentId,
        completedCount: completedCount,
        totalCount: totalCount,
        template: template,
      ),
    );
  }

  @override
  ConsumerState<ScratchStampSheet> createState() => _ScratchStampSheetState();
}

class _ScratchStampSheetState extends ConsumerState<ScratchStampSheet>
    with SingleTickerProviderStateMixin {
  final Path _strokePath = Path();
  final Set<int> _touchedCells = {};
  bool _isComplete = false;
  bool _rememberQuickMode = false;

  late final Set<int> _relevantCells = _computeRelevantCells();

  late final AnimationController _shrinkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _shrinkAnimation = CurvedAnimation(
    parent: _shrinkController,
    curve: Curves.easeInBack,
  );

  /// Grid cells (index = row * gridSize + col) whose center lies inside the
  /// stamp template's own shape — coverage is measured against this subset
  /// only, computed once (not per frame).
  Set<int> _computeRelevantCells() {
    final path = widget.template.buildPath(
      const Size(_kCanvasSize, _kCanvasSize),
    );
    const cellSize = _kCanvasSize / _kGridSize;
    final cells = <int>{};
    for (var row = 0; row < _kGridSize; row++) {
      for (var col = 0; col < _kGridSize; col++) {
        final center = Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
        if (path.contains(center)) {
          cells.add(row * _kGridSize + col);
        }
      }
    }
    return cells;
  }

  double get _coverage {
    if (_relevantCells.isEmpty) return 0;
    final touchedRelevant = _touchedCells.intersection(_relevantCells).length;
    return touchedRelevant / _relevantCells.length;
  }

  @override
  void dispose() {
    _shrinkController.dispose();
    super.dispose();
  }

  void _markPoint(Offset point) {
    const cellSize = _kCanvasSize / _kGridSize;
    final baseCol = (point.dx / cellSize).floor();
    final baseRow = (point.dy / cellSize).floor();
    final spread = (_kStrokeRadius / cellSize).ceil();
    for (var row = baseRow - spread; row <= baseRow + spread; row++) {
      if (row < 0 || row >= _kGridSize) continue;
      for (var col = baseCol - spread; col <= baseCol + spread; col++) {
        if (col < 0 || col >= _kGridSize) continue;
        final cellCenter = Offset(
          (col + 0.5) * cellSize,
          (row + 0.5) * cellSize,
        );
        if ((cellCenter - point).distance <= _kStrokeRadius) {
          _touchedCells.add(row * _kGridSize + col);
        }
      }
    }
  }

  void _handleScratchPoint(Offset point) {
    if (_isComplete) return;
    setState(() {
      _strokePath.addOval(
        Rect.fromCircle(center: point, radius: _kStrokeRadius),
      );
      _markPoint(point);
    });
    if (_coverage >= _kCompletionThreshold) {
      unawaited(_completeStamp());
    }
  }

  void _handleInstantFill() {
    if (_isComplete) return;
    setState(() {
      _strokePath.addRect(Offset.zero & const Size(_kCanvasSize, _kCanvasSize));
      _touchedCells.addAll(_relevantCells);
    });
    unawaited(_completeStamp());
  }

  Future<void> _completeStamp() async {
    if (_isComplete) return;
    _isComplete = true;
    HapticFeedback.mediumImpact();

    if (_rememberQuickMode) {
      await ref
          .read(practiceScratchModeStorageProvider(widget.studentId).notifier)
          .setQuickCheckEnabled(true);
    }

    if (!mounted) return;
    setState(() {}); // Paint the fully-revealed stamp before shrinking.
    await _shrinkController.forward();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final displayIndex = math.min(widget.completedCount + 1, widget.totalCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.practiceStampSheetTitle(displayIndex),
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            _isComplete
                ? AppStrings.practiceStampSheetComplete
                : AppStrings.practiceStampSheetHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          ScaleTransition(
            scale: Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(_shrinkAnimation),
            child: GestureDetector(
              key: scratchStampCanvasKey,
              onPanUpdate: (details) =>
                  _handleScratchPoint(details.localPosition),
              onLongPress: _handleInstantFill,
              child: SizedBox(
                width: _kCanvasSize,
                height: _kCanvasSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: StampFillPainter(
                        template: widget.template,
                        color: AppColors.paperAccent,
                      ),
                    ),
                    CustomPaint(
                      painter: ScratchMaskPainter(
                        template: widget.template,
                        strokePath: _strokePath,
                        maskColor: AppColors.paperDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _rememberQuickMode,
                activeColor: AppColors.paperOk,
                onChanged: (value) =>
                    setState(() => _rememberQuickMode = value ?? false),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _rememberQuickMode = !_rememberQuickMode),
                child: Text(
                  AppStrings.practiceStampQuickModeCheckbox,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
