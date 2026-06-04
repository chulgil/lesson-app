import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/loop_bookmark.dart';
import '../../../domain/value_objects/practice_loop_speeds.dart';
import 'bookmark_manager_sheet.dart';

/// Control row — repeat toggle, speed picker (5 steps), reset, count-in.
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.2
/// Tokens: paper background, BorderRadius.zero, elevation 0.
class LoopControls extends StatelessWidget {
  final bool repeatEnabled;
  final ValueChanged<bool> onRepeatChanged;

  final double speed;
  final ValueChanged<double> onSpeedChanged;

  final VoidCallback onReset;

  final bool countInEnabled;
  final ValueChanged<bool> onCountInChanged;

  final bool countInSoundEnabled;
  final ValueChanged<bool> onCountInSoundChanged;

  /// Bookmark selector data (#511). When [bookmarks] is empty the row collapses
  /// and only the "북마크 관리" affordance is shown.
  final List<LoopBookmark> bookmarks;
  final String? activeBookmarkId;
  final ValueChanged<String?>? onBookmarkSelected;
  final VoidCallback? onManageBookmarks;

  const LoopControls({
    super.key,
    required this.repeatEnabled,
    required this.onRepeatChanged,
    required this.speed,
    required this.onSpeedChanged,
    required this.onReset,
    required this.countInEnabled,
    required this.onCountInChanged,
    required this.countInSoundEnabled,
    required this.onCountInSoundChanged,
    this.bookmarks = const [],
    this.activeBookmarkId,
    this.onBookmarkSelected,
    this.onManageBookmarks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RepeatToggle(enabled: repeatEnabled, onChanged: onRepeatChanged),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _SpeedPicker(value: speed, onChanged: onSpeedChanged),
              ),
              const SizedBox(width: AppSpacing.space2),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(AppStrings.youtubeLoopResetSegment),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              _LabelledSwitch(
                label: AppStrings.youtubeLoopCountInToggle,
                value: countInEnabled,
                onChanged: onCountInChanged,
              ),
              const SizedBox(width: AppSpacing.space3),
              if (countInEnabled)
                _LabelledSwitch(
                  label: AppStrings.youtubeLoopCountInSoundToggle,
                  value: countInSoundEnabled,
                  onChanged: onCountInSoundChanged,
                ),
              const Spacer(),
              if (countInEnabled)
                Text(
                  AppStrings.youtubeLoopCountInDescription,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
            ],
          ),
          if (onManageBookmarks != null) ...[
            const SizedBox(height: AppSpacing.space2),
            _BookmarkRow(
              bookmarks: bookmarks,
              activeBookmarkId: activeBookmarkId,
              onBookmarkSelected: onBookmarkSelected,
              onManage: onManageBookmarks!,
            ),
          ],
        ],
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  final List<LoopBookmark> bookmarks;
  final String? activeBookmarkId;
  final ValueChanged<String?>? onBookmarkSelected;
  final VoidCallback onManage;

  const _BookmarkRow({
    required this.bookmarks,
    required this.activeBookmarkId,
    required this.onBookmarkSelected,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (bookmarks.isNotEmpty)
          Expanded(
            child: _BookmarkDropdown(
              bookmarks: bookmarks,
              activeBookmarkId: activeBookmarkId,
              onSelected: onBookmarkSelected,
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: AppSpacing.space2),
        TextButton(
          onPressed: onManage,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.paperAccent,
            minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: const Text(AppStrings.bookmarkManage),
        ),
      ],
    );
  }
}

class _BookmarkDropdown extends StatelessWidget {
  final List<LoopBookmark> bookmarks;
  final String? activeBookmarkId;
  final ValueChanged<String?>? onSelected;

  const _BookmarkDropdown({
    required this.bookmarks,
    required this.activeBookmarkId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
        borderRadius: BorderRadius.zero,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: activeBookmarkId,
          hint: const Text(
            AppStrings.bookmarkSelect,
            style: AppTypography.bodySmall,
          ),
          icon: const Icon(Icons.expand_more, color: AppColors.inkSecondary),
          onChanged: onSelected,
          items: [
            for (final bookmark in bookmarks)
              DropdownMenuItem<String?>(
                value: bookmark.id,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: BookmarkManagerSheet.colorFor(
                          bookmark.colorIndex,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Flexible(
                      child: Text(
                        bookmark.name,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepeatToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RepeatToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!enabled),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: enabled ? AppColors.paperAccentSoft : Colors.transparent,
          border: Border.all(
            color: enabled ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          enabled
              ? AppStrings.youtubeLoopRepeatOn
              : AppStrings.youtubeLoopRepeatOff,
          style: AppTypography.bodySmall.copyWith(
            color: enabled ? AppColors.paperAccent : AppColors.inkSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _SpeedPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppStrings.youtubeLoopSpeedLabel,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in PracticeLoopSpeeds.allowed)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space1),
                    child: _SpeedChip(
                      value: s,
                      selected: (value - s).abs() < 0.001,
                      onTap: () => onChanged(s),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final double value;
  final bool selected;
  final VoidCallback onTap;

  const _SpeedChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.paperAccent : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          '${value}x',
          style: AppTypography.captionSmall.copyWith(
            color: selected ? AppColors.paper : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LabelledSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LabelledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.paperAccent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: AppSpacing.space1),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
