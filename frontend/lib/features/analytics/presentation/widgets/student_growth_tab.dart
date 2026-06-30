// Analytics Tab 2: 학생별 성장.
// Spec: docs/specs/analytics/student_progress_dashboard_spec.md §2.2 Tab 2

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart' as dfmt;
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../practice/practice_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/analytics_models.dart';
import '../providers/analytics_providers.dart';
import 'analytics_error_view.dart';
import 'practice_weekly_line_chart.dart';
import 'repertoire_progress_list.dart';

// ignore: widget-smoke-test
/// Student growth tab content for AnalyticsDashboardScreen.
class StudentGrowthTab extends ConsumerStatefulWidget {
  const StudentGrowthTab({super.key});

  @override
  ConsumerState<StudentGrowthTab> createState() => _StudentGrowthTabState();
}

class _StudentGrowthTabState extends ConsumerState<StudentGrowthTab> {
  // #749: real teacher students (was hardcoded _mockStudents). null until the
  // list resolves; defaults to the first student, which auto-selects the only
  // student when the teacher has exactly one (mirrors subscription auto-select).
  String? _selectedStudentId;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.threeMonths;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AnalyticsErrorView(
        onRetry: () => ref.invalidate(studentsProvider),
      ),
      data: (students) {
        if (students.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.people_outline,
            title: AppStrings.studentsEmptyTitle,
            subtitle: AppStrings.studentsEmptySubtitle,
          );
        }

        // Keep the current pick if it still exists, otherwise default to the
        // first student (auto-selects the only student).
        if (_selectedStudentId == null ||
            !students.any((s) => s.id == _selectedStudentId)) {
          _selectedStudentId = students.first.id;
        }
        final selectedId = _selectedStudentId!;

        return Column(
          children: [
            _buildSelectors(students, selectedId),
            Expanded(child: _buildProgress(selectedId)),
          ],
        );
      },
    );
  }

  Widget _buildProgress(String studentId) {
    final progressAsync = ref.watch(
      studentProgressDataProvider(studentId, _selectedPeriod),
    );
    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AnalyticsErrorView(
        onRetry: () => ref.invalidate(
          studentProgressDataProvider(studentId, _selectedPeriod),
        ),
      ),
      data: (progress) => _buildContent(progress),
    );
  }

  Widget _buildSelectors(List<Student> students, String selectedId) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(
          bottom: BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStudentSelector(students, selectedId)),
          const SizedBox(width: AppSpacing.space3),
          _buildPeriodDropdown(),
        ],
      ),
    );
  }

  Widget _buildStudentSelector(List<Student> students, String selectedId) {
    // Single student → static label (no redundant 1-item dropdown).
    if (students.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          students.first.name,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        isDense: true,
        isExpanded: true,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        onChanged: (v) {
          if (v != null) setState(() => _selectedStudentId = v);
        },
        items: students.map((s) {
          return DropdownMenuItem(
            value: s.id,
            child: Text(s.name),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    final labels = {
      AnalyticsPeriod.oneMonth: AppStrings.analyticsPeriod1Month,
      AnalyticsPeriod.threeMonths: AppStrings.analyticsPeriod3Months,
      AnalyticsPeriod.sixMonths: AppStrings.analyticsPeriod6Months,
      AnalyticsPeriod.oneYear: AppStrings.analyticsPeriod12Months,
    };

    return DropdownButtonHideUnderline(
      child: DropdownButton<AnalyticsPeriod>(
        value: _selectedPeriod,
        isDense: true,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        onChanged: (v) {
          if (v != null) setState(() => _selectedPeriod = v);
        },
        items: labels.entries.map((e) {
          return DropdownMenuItem(value: e.key, child: Text(e.value));
        }).toList(),
      ),
    );
  }

  Widget _buildContent(StudentProgressData progress) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          studentProgressDataProvider(progress.studentId, _selectedPeriod),
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildSummaryCards(progress),
          const SizedBox(height: AppSpacing.space5),
          _buildPracticeChart(progress),
          const SizedBox(height: AppSpacing.space5),
          _buildRepertoireSection(progress),
          const SizedBox(height: AppSpacing.space5),
          _buildRecordingSection(progress),
          const SizedBox(height: AppSpacing.space5),
          _buildFeedbackSection(progress),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(StudentProgressData progress) {
    final prPct = (progress.practiceAchievementRate * 100).toStringAsFixed(1);
    final arPct = (progress.attendanceRate * 100).toStringAsFixed(1);
    // Streak comes from the single source of truth (practiceStreakProvider) via
    // the practice facade — not progress.practiceStreakDays. The cross-feature
    // dependency goes through the facade. See docs/specs/practice/streak_ssot.md.
    final streakDays = ref
        .watch(practiceStreakProvider(progress.studentId))
        .maybeWhen(data: (s) => s.currentStreak, orElse: () => 0);

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: AppStrings.analyticsAttendanceRateLabel,
            value: '$arPct%',
            color: AppColors.paperOk,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _MiniStatCard(
            label: AppStrings.analyticsPracticeRateLabel,
            value: '$prPct%',
            color: AppColors.paperAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _MiniStatCard(
            label: AppStrings.analyticsLessonCountLabel,
            value: AppStrings.analyticsLessonCountValueFormat(progress.attendedLessons),
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _MiniStatCard(
            label: AppStrings.analyticsStreakLabel,
            value: AppStrings.analyticsStreakDaysFormat(streakDays),
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeChart(StudentProgressData progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.analyticsPracticeTrend, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: PracticeWeeklyLineChart(data: progress.weeklyPractice),
        ),
      ],
    );
  }

  Widget _buildRepertoireSection(StudentProgressData progress) {
    if (progress.repertoire.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.analyticsRepertoireProgress, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        RepertoireProgressList(pieces: progress.repertoire),
      ],
    );
  }

  Widget _buildRecordingSection(StudentProgressData progress) {
    if (progress.recordings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.analyticsRecordingHistory, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        ...progress.recordings.map((r) => _RecordingRow(recording: r)),
      ],
    );
  }

  Widget _buildFeedbackSection(StudentProgressData progress) {
    if (progress.feedbackHighlights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.analyticsFeedbackSummary, style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space3),
        ...progress.feedbackHighlights.map((f) => _FeedbackRow(feedback: f)),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        border: Border(left: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingRow extends StatelessWidget {
  const _RecordingRow({required this.recording});

  final RecordingEntry recording;

  @override
  Widget build(BuildContext context) {
    final dur = recording.durationSeconds;
    final mm = dur ~/ 60;
    final ss = (dur % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.paperAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dfmt.formatDateYMD(recording.recordedAt),
                      style: NotebookTypography.metaMono.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    if (recording.pieceTitle != null)
                      Text(
                        '${recording.pieceTitle}  ($mm:$ss)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    if (recording.teacherNote != null)
                      Text(
                        recording.teacherNote!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                size: 24,
                color: AppColors.inkTertiary,
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.inkQuaternary),
      ],
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.feedback});

  final FeedbackHighlight feedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dfmt.formatDateYMD(feedback.lessonDate),
                style: NotebookTypography.metaMono.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  feedback.summaryText,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.inkQuaternary),
      ],
    );
  }
}
