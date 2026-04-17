import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../practice/domain/entities/student_practice_overview.dart';
import '../../../../practice/presentation/providers/practice_overview_provider.dart';
import '../../../../practice/presentation/providers/recording_feedback_provider.dart';
import '../../../../practice/presentation/widgets/teacher_feedback_sheet.dart';

/// Tab content showing practice progress and statistics
class StudentPracticeTab extends ConsumerWidget {
  final String studentId;

  const StudentPracticeTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(studentPracticeOverviewProvider(studentId));

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              '연습 데이터를 불러올 수 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
      data:
          (overview) => ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              _WeeklySummaryCard(overview: overview),
              const SizedBox(height: AppSpacing.space4),
              _WeeklyPracticeGrid(entries: overview.weeklyEntries),
              if (overview.sharedRecordings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space4),
                _SharedRecordingsSection(
                  recordings: overview.sharedRecordings,
                  studentId: studentId,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              _DetailStatsButton(studentId: studentId),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
    );
  }
}

/// Summary card: practice days, total time, shared recordings count
class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.overview});

  final StudentPracticeOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.space3),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 주 연습 요약', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.calendar_today_outlined,
                  label: '연습 일수',
                  value:
                      '${overview.practiceDaysThisWeek}/${overview.totalDaysInWeek}일',
                  color: _practiceRateColor(overview.practiceRate),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.timer_outlined,
                  label: '총 연습시간',
                  value: overview.formattedTotalTime,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.mic_outlined,
                  label: '공유 녹음',
                  value: '${overview.sharedRecordings.length}개',
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _practiceRateColor(double rate) {
    if (rate >= 0.7) return AppColors.practiceGood;
    if (rate >= 0.4) return AppColors.practiceNormal;
    return AppColors.practicePoor;
  }
}

/// Individual summary metric item
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppSpacing.space1),
        Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
        const SizedBox(height: AppSpacing.space1),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// 7-day practice grid showing each day with practice minutes
class _WeeklyPracticeGrid extends StatelessWidget {
  const _WeeklyPracticeGrid({required this.entries});

  final List<DailyPracticeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final maxMinutes = entries
        .map((e) => e.practiceMinutes)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.space3),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('주간 연습 현황', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children:
                entries.map((entry) {
                  final isToday =
                      entry.date.year == today.year &&
                      entry.date.month == today.month &&
                      entry.date.day == today.day;
                  return Expanded(
                    child: _DayColumn(
                      entry: entry,
                      maxMinutes: maxMinutes,
                      isToday: isToday,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Single day column in weekly grid with bar + label
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.entry,
    required this.maxMinutes,
    required this.isToday,
  });

  final DailyPracticeEntry entry;
  final int maxMinutes;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Bar height proportional to max minutes, min height for practiced days
    const maxBarHeight = 60.0;
    const minBarHeight = 6.0;
    final barHeight =
        maxMinutes > 0 && entry.practiceMinutes > 0
            ? (entry.practiceMinutes / maxMinutes * maxBarHeight).clamp(
              minBarHeight,
              maxBarHeight,
            )
            : minBarHeight;

    final barColor =
        entry.hasPracticed
            ? AppColors.practiceGood
            : AppColors.scheduleMutedBackground;

    final dayLabel = LessonDateUtils.getWeekdayNameKorean(entry.date.weekday);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: Column(
        children: [
          // Practice minutes label
          Text(
            entry.hasPracticed ? '${entry.practiceMinutes}' : '-',
            style: AppTypography.caption.copyWith(
              color:
                  entry.hasPracticed
                      ? AppColors.textPrimaryLight
                      : AppColors.textTertiaryLight,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          // Bar area: 고정 높이(maxBarHeight) 내에서 실제 막대를 하단 정렬
          SizedBox(
            height: maxBarHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: barHeight,
                width: 14, // 고정 막대 너비 (seconds-level readability)
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppSpacing.space1),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          // Day label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space1,
              vertical: 2,
            ),
            decoration:
                isToday
                    ? BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.space1),
                    )
                    : null,
            child: Text(
              dayLabel,
              style: AppTypography.caption.copyWith(
                color:
                    isToday
                        ? AppColors.surfaceLight
                        : AppColors.textSecondaryLight,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// List of shared recordings from the student
class _SharedRecordingsSection extends StatelessWidget {
  const _SharedRecordingsSection({
    required this.recordings,
    required this.studentId,
  });

  final List<SharedRecording> recordings;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.space3),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_outlined, size: 18, color: AppColors.info),
              const SizedBox(width: AppSpacing.space2),
              Text('공유된 녹음', style: AppTypography.headingSmall),
              const Spacer(),
              Text(
                '${recordings.length}개',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          ...recordings.map(
            (recording) =>
                _RecordingTile(recording: recording, studentId: studentId),
          ),
        ],
      ),
    );
  }
}

/// Individual recording tile — tap to open feedback sheet.
class _RecordingTile extends ConsumerWidget {
  const _RecordingTile({required this.recording, required this.studentId});

  final SharedRecording recording;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackCount = ref.watch(
      recordingFeedbackCountProvider(recording.recordingId),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: InkWell(
        onTap:
            () => TeacherFeedbackSheet.show(
              context,
              recording: recording,
              studentId: studentId,
              teacherId: 'teacher_current',
            ),
        borderRadius: BorderRadius.circular(AppSpacing.space2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            children: [
              _TileLeading(feedbackCount: feedbackCount),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.repertoireName,
                      style: AppTypography.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            recording.sectionName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (feedbackCount > 0) ...[
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            '· ${AppStrings.recordingFeedbackCount(feedbackCount)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recording.formattedDuration,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  if (recording.bpm != null)
                    Text(
                      '${recording.bpm} BPM',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileLeading extends StatelessWidget {
  const _TileLeading({required this.feedbackCount});

  final int feedbackCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSpacing.space2),
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        if (feedbackCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceLight, width: 1.5),
              ),
              child: Text(
                '$feedbackCount',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom button for navigating to detailed statistics
class _DetailStatsButton extends StatelessWidget {
  const _DetailStatsButton({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Navigate to practice statistics detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상세 통계 기능은 준비 중입니다'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.bar_chart_outlined, size: 18),
      label: const Text('상세 통계 보기'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.space2),
        ),
      ),
    );
  }
}
