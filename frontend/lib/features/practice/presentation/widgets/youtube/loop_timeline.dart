import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../domain/entities/loop_bookmark.dart';
import '../../extensions/audio_mix_visuals.dart';
import 'bookmark_manager_sheet.dart';

/// Loop timeline — paper background, dashed connector, draggable A/B markers,
/// playhead overlay. No rounded corners.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.2, §4.5
class LoopTimeline extends StatelessWidget {
  final double totalDurationSeconds;
  final double currentPositionSeconds;
  final double startSeconds;
  final double endSeconds;
  final bool editable;
  final ValueChanged<double>? onStartChanged;
  final ValueChanged<double>? onEndChanged;

  /// Optional memo positions (seconds). Each entry renders as a small
  /// paperAccent dot. #510.
  final List<int> memoSeconds;

  /// Optional list of student-authored bookmark passages. Each renders as a
  /// small coloured bar above the dashed line (colour driven by
  /// [BookmarkManagerSheet.colorFor]). Spec: #511.
  final List<LoopBookmark> bookmarks;

  /// Id of the currently-selected bookmark (rendered with a thicker bar). #511.
  final String? activeBookmarkId;

  static const _height = 48.0;
  static const _markerSize = 16.0;
  static const _memoDotSize = 6.0;
  static const _bookmarkBarHeight = 4.0;
  static const _bookmarkBarHeightActive = 6.0;

  const LoopTimeline({
    super.key,
    required this.totalDurationSeconds,
    required this.currentPositionSeconds,
    required this.startSeconds,
    required this.endSeconds,
    this.editable = true,
    this.onStartChanged,
    this.onEndChanged,
    this.memoSeconds = const [],
    this.bookmarks = const [],
    this.activeBookmarkId,
  });

  double _fraction(double seconds) {
    if (totalDurationSeconds <= 0) return 0;
    return (seconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  formatLoopSeconds(startSeconds.round()),
                  style: NotebookTypography.tempoMono.copyWith(
                    color: AppColors.paperAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space1,
                  ),
                  child: Text(
                    '${formatLoopSeconds(currentPositionSeconds.round())} '
                    '/ ${formatLoopSeconds(totalDurationSeconds.round())}',
                    style: NotebookTypography.tempoMono.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  formatLoopSeconds(endSeconds.round()),
                  style: NotebookTypography.tempoMono.copyWith(
                    color: AppColors.paperAccent,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: _height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dashed connector full width
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: AppColors.inkQuaternary,
                        ),
                      ),
                    ),
                    // Active range overlay
                    Positioned(
                      left: _fraction(startSeconds) * width,
                      width:
                          (_fraction(endSeconds) - _fraction(startSeconds)) *
                          width,
                      top: _height / 2 - 2,
                      child: Container(height: 4, color: AppColors.paperAccent),
                    ),
                    // Bookmark bars (#511) — drawn just above the dashed line
                    // so the active range overlay still pops. Each bookmark
                    // uses its own slot color so students can tell them apart.
                    for (final bookmark in bookmarks)
                      Positioned(
                        left:
                            _fraction(bookmark.startSeconds.toDouble()) * width,
                        width:
                            (_fraction(bookmark.endSeconds.toDouble()) -
                                _fraction(bookmark.startSeconds.toDouble())) *
                            width,
                        top:
                            _height / 2 -
                            (bookmark.id == activeBookmarkId
                                ? _bookmarkBarHeightActive
                                : _bookmarkBarHeight) -
                            6,
                        child: Semantics(
                          label:
                              '${AppStrings.bookmarkMarkerSemantic} ${bookmark.name}',
                          child: Container(
                            height:
                                bookmark.id == activeBookmarkId
                                    ? _bookmarkBarHeightActive
                                    : _bookmarkBarHeight,
                            color: BookmarkManagerSheet.colorFor(
                              bookmark.colorIndex,
                            ),
                          ),
                        ),
                      ),
                    // Memo dots (#510) — rendered behind playhead.
                    for (final seconds in memoSeconds)
                      Positioned(
                        left:
                            _fraction(seconds.toDouble()) * width -
                            _memoDotSize / 2,
                        top: _height / 2 - _memoDotSize / 2,
                        child: Semantics(
                          label: AppStrings.loopMemoMarkerSemantic,
                          child: Container(
                            width: _memoDotSize,
                            height: _memoDotSize,
                            decoration: const BoxDecoration(
                              color: AppColors.paperAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    // Playhead
                    Positioned(
                      left: _fraction(currentPositionSeconds) * width - 1,
                      child: Container(
                        width: 2,
                        height: _height,
                        color: AppColors.ink,
                      ),
                    ),
                    // Start marker
                    Positioned(
                      left: _fraction(startSeconds) * width - _markerSize / 2,
                      child: _Marker(
                        editable: editable,
                        semanticLabel:
                            AppStrings.youtubeLoopMarkerSemanticStart,
                        onDrag:
                            editable
                                ? (delta) {
                                  final newSeconds =
                                      startSeconds +
                                      delta.dx / width * totalDurationSeconds;
                                  onStartChanged?.call(
                                    newSeconds.clamp(0.0, endSeconds - 1),
                                  );
                                }
                                : null,
                      ),
                    ),
                    // End marker
                    Positioned(
                      left: _fraction(endSeconds) * width - _markerSize / 2,
                      child: _Marker(
                        editable: editable,
                        semanticLabel: AppStrings.youtubeLoopMarkerSemanticEnd,
                        onDrag:
                            editable
                                ? (delta) {
                                  final newSeconds =
                                      endSeconds +
                                      delta.dx / width * totalDurationSeconds;
                                  onEndChanged?.call(
                                    newSeconds.clamp(
                                      startSeconds + 1,
                                      totalDurationSeconds,
                                    ),
                                  );
                                }
                                : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  final bool editable;
  final String semanticLabel;
  final void Function(Offset delta)? onDrag;

  const _Marker({
    required this.editable,
    required this.semanticLabel,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      enabled: editable,
      child: GestureDetector(
        onHorizontalDragUpdate: onDrag == null ? null : (d) => onDrag!(d.delta),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: LoopTimeline._markerSize,
          height: LoopTimeline._markerSize,
          decoration: BoxDecoration(
            color: AppColors.paperAccent,
            shape: BoxShape.circle,
            boxShadow:
                editable
                    ? [
                      BoxShadow(
                        color: AppColors.paperAccentSelected,
                        blurRadius: 4,
                      ),
                    ]
                    : null,
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5;
    const dash = 4.0;
    const gap = 4.0;
    final centerY = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset((x + dash).clamp(0, size.width), centerY),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
