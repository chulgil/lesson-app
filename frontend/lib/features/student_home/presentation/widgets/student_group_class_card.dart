// Enrolled cohort class as an agenda row (J12, P1-2).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../schedule/schedule_facade.dart';

/// One class the student is enrolled in, shown on the day it meets.
///
/// Roster rows only — a class the student could join but has not been assigned
/// to never appears here. Discovery lives on the teacher detail screen (D3).
class StudentGroupClassCard extends ConsumerWidget {
  const StudentGroupClassCard({
    super.key,
    required this.groupClass,
    required this.studentId,
    required this.date,
  });

  final GroupClass groupClass;
  final String studentId;

  /// The agenda day this row was rendered for — used to open that day's session.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: NotebookCard(
        child: InkWell(
          onTap: () => _openDetail(context, ref),
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(
                  label:
                      groupClass.type == GroupClassType.regular
                          ? AppStrings.groupClassRegular
                          : AppStrings.groupClassDropin,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  groupClass.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.groupClassAgendaSummary(
                    groupClass.repeatTimeOfDay ?? '',
                    groupClass.durationMinutes,
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens this day's session, falling back to the next upcoming one — the row
  /// is derived from the repeat rule, so a session may not exist for every day.
  Future<void> _openDetail(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final List<GroupClassSchedule> schedules;
    try {
      schedules = await ref.read(
        groupClassSchedulesProvider(groupClass.id).future,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassInfoUnavailable),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final onDate = schedules.where(
      (s) =>
          s.startTime.year == date.year &&
          s.startTime.month == date.month &&
          s.startTime.day == date.day,
    );
    final now = DateTime.now();
    final upcoming = schedules.where((s) => s.startTime.isAfter(now));
    final schedule = onDate.firstOrNull ?? upcoming.firstOrNull;
    if (schedule == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassesNoSessionYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    context.push(
      AppRoutes.groupClassDetail.replaceFirst(':id', schedule.id),
      extra: {
        'scheduleId': schedule.id,
        'studentId': studentId,
        'schedule': schedule,
        'groupClass': groupClass,
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: const BoxDecoration(color: AppColors.paperAccentSoft),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
