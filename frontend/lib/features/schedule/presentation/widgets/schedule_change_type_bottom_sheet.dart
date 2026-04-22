import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/lesson_schedule_change.dart';

/// Shows a bottom sheet to choose between single lesson or bulk schedule change.
/// Returns [ScheduleChangeType] or null if cancelled.
Future<ScheduleChangeType?> showScheduleChangeTypeBottomSheet(
  BuildContext context,
) {
  return showModalBottomSheet<ScheduleChangeType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paperDark,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _ScheduleChangeTypeBottomSheet(),
  );
}

class _ScheduleChangeTypeBottomSheet extends StatelessWidget {
  const _ScheduleChangeTypeBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            const Center(
              child: BottomSheetHandle(
                margin: EdgeInsets.only(bottom: AppSpacing.space4),
              ),
            ),
            // Title
            // Notebook × Score: 바텀시트 커스텀 헤더 제목도 Playfair appBarTitle 로 통일 (§7.27 패턴).
            Text(
              AppStrings.scheduleChangeTypeTitle,
              style: NotebookTypography.appBarTitle,
            ),
            const SizedBox(height: AppSpacing.space4),
            // Single lesson option
            _ChangeTypeCard(
              icon: Icons.today_outlined,
              label: AppStrings.scheduleChangeSingleLabel,
              description: AppStrings.scheduleChangeSingleDesc,
              onTap:
                  () => Navigator.pop(context, ScheduleChangeType.singleLesson),
            ),
            const SizedBox(height: AppSpacing.space3),
            // Bulk change option
            _ChangeTypeCard(
              icon: Icons.date_range_outlined,
              label: AppStrings.scheduleChangeBulkLabel,
              description: AppStrings.scheduleChangeBulkDesc,
              onTap:
                  () => Navigator.pop(context, ScheduleChangeType.bulkChange),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}

class _ChangeTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ChangeTypeCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                ),
                child: Icon(icon, color: AppColors.paperAccent, size: 24),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
