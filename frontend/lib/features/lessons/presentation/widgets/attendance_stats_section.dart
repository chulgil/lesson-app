// Attendance statistics section widget for student detail screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/attendance_stats.dart';
import '../providers/attendance_providers.dart';

/// Attendance statistics section for student detail.
class AttendanceStatsSection extends ConsumerWidget {
  final String studentId;

  const AttendanceStatsSection({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(studentAttendanceStatsProvider(studentId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox.shrink(),
      data: (stats) => _buildContent(stats),
    );
  }

  Widget _buildContent(AttendanceStats stats) {
    if (stats.totalLessons == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출석 현황',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(color: AppColors.paper),
          child: Column(
            children: [
              // Attendance rate circle
              _buildAttendanceRate(stats),

              const SizedBox(height: AppSpacing.space4),

              Divider(height: 1, color: AppColors.inkQuaternary),

              const SizedBox(height: AppSpacing.space4),

              // Status breakdown
              _buildStatusBreakdown(stats),

              if (stats.monthlyBreakdown.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                Divider(height: 1, color: AppColors.inkQuaternary),
                const SizedBox(height: AppSpacing.space4),
                _buildMonthlyTable(stats),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceRate(AttendanceStats stats) {
    final rate = stats.attendanceRate;
    final rateColor =
        rate >= 90
            ? AppColors.paperOk
            : rate >= 70
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Row(
      children: [
        // Rate circle
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 6,
                backgroundColor: AppColors.inkQuaternary,
                color: rateColor,
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rateColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.space4),

        // Summary text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '출석률',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '전체 ${stats.totalLessons}회 중 ${stats.completedLessons}회 출석',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(AttendanceStats stats) {
    return Column(
      children: [
        _buildStatusRow('출석 완료', stats.completedLessons, AppColors.paperOk),
        const SizedBox(height: AppSpacing.space2),
        _buildStatusRow(
          '학생 불참',
          stats.absentCount,
          AppColors.paperAccent,
          deducted: true,
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildStatusRow(
          '무단 결석',
          stats.noShowCount,
          AppColors.paperAccent,
          deducted: true,
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildStatusRow(
          '당일 취소',
          stats.cancelledByStudentLateCount,
          AppColors.paperAccent,
          deducted: true,
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildStatusRow('선생님 취소', stats.cancelledByTeacherCount, AppColors.ink),
        const SizedBox(height: AppSpacing.space2),
        _buildStatusRow('상호 합의 취소', stats.mutualCancelledCount, AppColors.ink),
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    int count,
    Color color, {
    bool deducted = false,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.zero,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Row(
            children: [
              Text(label, style: AppTypography.bodySmall),
              if (deducted)
                Text(
                  ' (수강권 차감)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '$count회',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMonthlyTable(AttendanceStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '월별 출석 현황',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Table header
        Row(
          children: [
            _tableCell('월', flex: 2, isHeader: true),
            _tableCell('전체', isHeader: true),
            _tableCell('출석', isHeader: true),
            _tableCell('출석률', isHeader: true),
          ],
        ),
        Divider(height: 1, color: AppColors.inkQuaternary),

        // Table rows (show last 6 months)
        ...stats.monthlyBreakdown.take(6).map((m) {
          final rate = m.attendanceRate;
          final rateColor =
              rate >= 90
                  ? AppColors.paperOk
                  : rate >= 70
                  ? AppColors.paperAccent
                  : AppColors.paperAccent;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _tableCell(m.monthLabel, flex: 2),
                    _tableCell('${m.totalLessons}'),
                    _tableCell('${m.completed}'),
                    Expanded(
                      child: Text(
                        '${rate.toStringAsFixed(0)}%',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: rateColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.inkQuaternary.withValues(alpha: 0.5),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableCell(String text, {int flex = 1, bool isHeader = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
        child: Text(
          text,
          style:
              isHeader
                  ? AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSecondary,
                  )
                  : AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
