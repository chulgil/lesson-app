import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../extensions/audio_mix_visuals.dart';

/// Compact visual affordance — placed on section cards to signal that the
/// section has a teacher-marked YouTube video.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.1, §4.7
///
/// Tokens used: [NotebookGlyph.chevronRight] (signature) + tempoMono label.
class SectionVideoAffordance extends StatelessWidget {
  /// Loop start seconds (teacher default or student override).
  final int? startSeconds;

  /// Loop end seconds.
  final int? endSeconds;

  /// When true, lays out icon + label vertically (tile-end).
  /// When false (default) lays out horizontally.
  final bool stacked;

  const SectionVideoAffordance({
    super.key,
    required this.startSeconds,
    required this.endSeconds,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasRange = startSeconds != null && endSeconds != null;
    final label = hasRange
        ? '${AppStrings.youtubeLoopSectionLabel} '
              '${formatLoopSeconds(startSeconds!)}-${formatLoopSeconds(endSeconds!)}'
        : AppStrings.youtubeLoopAffordanceSubtitle;

    final glyph = NotebookGlyph(
      NotebookGlyph.chevronRight,
      size: 14,
      color: AppColors.paperAccent,
      semanticLabel: AppStrings.youtubeLoopAffordanceSubtitle,
    );

    final text = Text(
      label,
      style: NotebookTypography.tempoMono.copyWith(
        color: AppColors.paperAccent,
      ),
      overflow: TextOverflow.ellipsis,
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [glyph, const SizedBox(height: 2), text],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(width: AppSpacing.space1),
        Flexible(child: text),
      ],
    );
  }
}
