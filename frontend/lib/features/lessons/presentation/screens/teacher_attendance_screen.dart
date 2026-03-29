import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../domain/entities/lesson.dart';
import '../providers/attendance_providers.dart';

/// Teacher-wide attendance overview screen (spec 3.4).
///
/// Shows:
/// - Overall attendance rate with progress bar
/// - Per-student attendance rates (sorted lowest first)
/// - Recent absence/noShow history
class TeacherAttendanceScreen extends ConsumerWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(teacherAttendanceOverviewProvider);
    final studentNames = ref.watch(studentNameMapProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('출석 현황')),
      body: overviewAsync.when(
        data: (overview) => _buildContent(context, overview, studentNames),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TeacherAttendanceOverview overview,
    Map<String, String> studentNames,
  ) {
    if (overview.totalCountable == 0) {
      return Center(
        child: Text(
          '출석 데이터가 없습니다',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall rate
          _buildOverallRate(overview),

          const SizedBox(height: AppSpacing.space6),

          // Per-student rates
          Text(AppStrings.studentAttendanceRates,
              style: AppTypography.headingMedium),
          const SizedBox(height: AppSpacing.space3),
          ...overview.studentRates.map(
            (sr) => _buildStudentRow(sr, studentNames[sr.studentId] ?? sr.studentId),
          ),

          if (overview.recentAbsences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),

            // Recent absences
            Text(AppStrings.recentAbsences,
                style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space3),
            ...overview.recentAbsences.map(
              (ar) => _buildAbsenceRow(ar, studentNames[ar.studentId] ?? ar.studentId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallRate(TeacherAttendanceOverview overview) {
    final rate = overview.overallRate;
    final color = rate >= 90
        ? AppColors.success
        : rate >= 70
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.overallAttendanceRate}  ${rate.toStringAsFixed(1)}%',
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${overview.totalCompleted}/${overview.totalCountable}회',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentAttendanceRate sr, String name) {
    final rate = sr.rate;
    final color = rate >= 90
        ? AppColors.success
        : rate >= 70
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: AppTypography.bodyMedium),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rate / 100,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          SizedBox(
            width: 80,
            child: Text(
              '${rate.toStringAsFixed(0)}% (${sr.completed}/${sr.total})',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceRow(AbsenceRecord ar, String name) {
    final statusLabel = switch (ar.status) {
      LessonStatus.studentAbsent => '결석',
      LessonStatus.noShow => '노쇼',
      LessonStatus.cancelledByStudentLate => '당일 취소',
      _ => '',
    };

    final isDeducted = ar.status.isDeducted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Text(
            '${ar.date.month}/${ar.date.day}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              '$name - $statusLabel',
              style: AppTypography.bodyMedium,
            ),
          ),
          if (isDeducted)
            Text(
              AppStrings.subscriptionDeducted,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }
}
