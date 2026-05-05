import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../schedule/schedule_facade.dart';
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

    return NotebookScreenScaffold(
      appBar: AppBar(title: const Text(AppStrings.attendanceTitle)),
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
          AppStrings.noAttendanceData,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
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
          // Notebook × Score: 출석 리스트 섹션 제목 — Playfair sectionTitle (§7.17).
          Text(
            AppStrings.studentAttendanceRates,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space3),
          ...overview.studentRates.map(
            (sr) => _buildStudentRow(
              sr,
              studentNames[sr.studentId] ?? sr.studentId,
            ),
          ),

          if (overview.recentAbsences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),

            // Recent absences
            // Notebook × Score: 최근 결석 섹션 제목 — Playfair sectionTitle (§7.17).
            Text(
              AppStrings.recentAbsences,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...overview.recentAbsences.map(
              (ar) => _buildAbsenceRow(
                ar,
                studentNames[ar.studentId] ?? ar.studentId,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallRate(TeacherAttendanceOverview overview) {
    final rate = overview.overallRate;
    final color =
        rate >= 90
            ? AppColors.paperOk
            : rate >= 70
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
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
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.inkQuaternary,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '${overview.totalCompleted}/${overview.totalCountable}회',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(StudentAttendanceRate sr, String name) {
    final rate = sr.rate;
    final color =
        rate >= 90
            ? AppColors.paperOk
            : rate >= 70
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: AppTypography.bodyMedium)),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: rate / 100,
                minHeight: 6,
                backgroundColor: AppColors.inkQuaternary,
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
                color: AppColors.inkSecondary,
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
      LessonStatus.studentAbsent => AppStrings.statusAbsent,
      LessonStatus.noShow => AppStrings.statusNoShow,
      LessonStatus.cancelledByStudentLate => AppStrings.statusSameDayCancel,
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
              color: AppColors.inkSecondary,
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
                color: AppColors.paperAccent,
              ),
            ),
        ],
      ),
    );
  }
}
