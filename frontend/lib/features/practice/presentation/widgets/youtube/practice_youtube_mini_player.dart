import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_glyph.dart';
import 'practice_youtube_player.dart';

/// Compact YouTube player for the recording screen.
///
/// Shows the section title + an expand button. Tapping the expand button
/// opens the full [PracticeYoutubePlayer] in a modal sheet.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.3
// ignore: widget-smoke-test
class PracticeYoutubeMiniPlayer extends StatelessWidget {
  final String videoId;
  final String sectionId;
  final String sectionTitle;
  final int? teacherStartSeconds;
  final int? teacherEndSeconds;

  const PracticeYoutubeMiniPlayer({
    super.key,
    required this.videoId,
    required this.sectionId,
    required this.sectionTitle,
    this.teacherStartSeconds,
    this.teacherEndSeconds,
  });

  Future<void> _openFullscreen(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SizedBox(
          height: mediaQuery.size.height * 0.9,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          sectionTitle,
                          style: AppTypography.headingSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.youtubeLoopExitFullscreen,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    child: PracticeYoutubePlayer(
                      videoId: videoId,
                      sectionId: sectionId,
                      teacherStartSeconds: teacherStartSeconds,
                      teacherEndSeconds: teacherEndSeconds,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Row(
        children: [
          const NotebookGlyph(
            NotebookGlyph.chevronRight,
            size: 16,
            color: AppColors.paperAccent,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.youtubeLoopMiniPlayerTitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                Text(
                  sectionTitle,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openFullscreen(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperAccent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(AppStrings.youtubeLoopMiniPlayerOpen),
          ),
        ],
      ),
    );
  }
}
