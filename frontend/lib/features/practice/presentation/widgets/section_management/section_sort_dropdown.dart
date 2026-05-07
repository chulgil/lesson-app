import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/section_sort_type.dart';
import '../../providers/section_sort_provider.dart';

/// Dropdown for selecting section sort type
class SectionSortDropdown extends ConsumerWidget {
  final String? repertoireId;

  const SectionSortDropdown({super.key, this.repertoireId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sectionSortTypeStateProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SectionSortType>(
          value: currentSort,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.inkSecondary),
          isDense: true,
          style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
          items:
              SectionSortType.values.map((type) {
                return DropdownMenuItem<SectionSortType>(
                  value: type,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIcon(type),
                        size: 16,
                        color:
                            currentSort == type
                                ? AppColors.paperAccent
                                : AppColors.inkSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color:
                              currentSort == type
                                  ? AppColors.paperAccent
                                  : AppColors.ink,
                          fontWeight:
                              currentSort == type
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (newType) {
            if (newType != null) {
              ref
                  .read(sectionSortTypeStateProvider.notifier)
                  .setSortType(newType);

              // If switching to custom, apply current order
              if (newType == SectionSortType.custom && repertoireId != null) {
                ref
                    .read(sectionOrderNotifierProvider.notifier)
                    .applySortOrder(repertoireId!, newType);
              }
            }
          },
        ),
      ),
    );
  }

  IconData _getIcon(SectionSortType type) {
    switch (type) {
      case SectionSortType.createdDesc:
        return Icons.arrow_downward;
      case SectionSortType.createdAsc:
        return Icons.arrow_upward;
      case SectionSortType.nameAsc:
        return Icons.sort_by_alpha;
      case SectionSortType.measureAsc:
        return Icons.music_note;
      case SectionSortType.lastPracticedDesc:
        return Icons.schedule;
      case SectionSortType.custom:
        return Icons.drag_handle;
    }
  }
}
