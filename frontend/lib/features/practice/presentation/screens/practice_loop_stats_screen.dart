import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/practice_loop_stats.dart';
import '../providers/practice_loop_stats_provider.dart';
import '../widgets/stats/student_loop_heatmap.dart';
import '../widgets/stats/student_repeat_chart.dart';

/// Teacher-side stats screen for §3.5 YouTube 구간 반복 연습 (#512).
///
/// Two modes:
/// - Without [studentId] → summary list of all students with totals.
/// - With [studentId] → drill-down chart + heatmap for one student.
class PracticeLoopStatsScreen extends ConsumerStatefulWidget {
  /// Optional — when provided the screen jumps straight to a single student.
  final String? studentId;

  const PracticeLoopStatsScreen({super.key, this.studentId});

  @override
  ConsumerState<PracticeLoopStatsScreen> createState() =>
      _PracticeLoopStatsScreenState();
}

class _PracticeLoopStatsScreenState
    extends ConsumerState<PracticeLoopStatsScreen> {
  PracticeLoopStatsWindow _window = PracticeLoopStatsWindow.weekly;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.teacherStatsTitle),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WindowToggle(
              window: _window,
              onChanged: (w) => setState(() => _window = w),
            ),
            Expanded(
              child:
                  _selectedStudentId == null
                      ? _SummaryView(
                        window: _window,
                        onSelectStudent:
                            (id) => setState(() => _selectedStudentId = id),
                      )
                      : _StudentDrilldownView(
                        studentId: _selectedStudentId!,
                        window: _window,
                        onBack:
                            widget.studentId != null
                                ? null
                                : () =>
                                    setState(() => _selectedStudentId = null),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowToggle extends StatelessWidget {
  final PracticeLoopStatsWindow window;
  final ValueChanged<PracticeLoopStatsWindow> onChanged;

  const _WindowToggle({required this.window, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      color: AppColors.paper,
      child: Row(
        children: [
          _Pill(
            label: AppStrings.teacherStatsWeekly,
            selected: window == PracticeLoopStatsWindow.weekly,
            onTap: () => onChanged(PracticeLoopStatsWindow.weekly),
          ),
          const SizedBox(width: AppSpacing.space2),
          _Pill(
            label: AppStrings.teacherStatsMonthly,
            selected: window == PracticeLoopStatsWindow.monthly,
            onTap: () => onChanged(PracticeLoopStatsWindow.monthly),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.paperAccent : AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: selected ? AppColors.paper : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  final PracticeLoopStatsWindow window;
  final ValueChanged<String> onSelectStudent;

  const _SummaryView({required this.window, required this.onSelectStudent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(practiceLoopStatsSummaryProvider(window: window));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                e.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
      data: (students) {
        if (students.isEmpty) {
          return Center(
            child: Text(
              AppStrings.teacherStatsEmpty,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.space4),
          itemCount: students.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space2),
          itemBuilder: (context, index) {
            final s = students[index];
            return _StudentCard(
              stats: s,
              onTap: () => onSelectStudent(s.studentId),
            );
          },
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentRepeatStats stats;
  final VoidCallback onTap;

  const _StudentCard({required this.stats, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.studentName ?? stats.studentId,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '${AppStrings.teacherStatsTotalRepeats}: '
                    '${stats.totalRepeats}${AppStrings.teacherStatsRepeatsUnit}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  if (stats.lastPlayedAt != null) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${AppStrings.teacherStatsLastPlayed}: '
                      '${_formatRelative(stats.lastPlayedAt!)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }

  static String _formatRelative(DateTime when) {
    final now = DateTime.now();
    final diff = now.difference(when);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _StudentDrilldownView extends ConsumerWidget {
  final String studentId;
  final PracticeLoopStatsWindow window;
  final VoidCallback? onBack;

  const _StudentDrilldownView({
    required this.studentId,
    required this.window,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      practiceLoopStatsForStudentProvider(studentId: studentId, window: window),
    );
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Text(
                e.toString(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
      data: (data) {
        if (data.rows.isEmpty) {
          return Center(
            child: Text(
              AppStrings.teacherStatsStudentEmpty,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            if (onBack != null)
              _BackHeader(totalRepeats: data.totalRepeats, onBack: onBack!),
            if (onBack == null) _StatsHeader(totalRepeats: data.totalRepeats),
            const SizedBox(height: AppSpacing.space4),
            StudentRepeatChart(rows: data.rows),
            const SizedBox(height: AppSpacing.space4),
            StudentLoopHeatmap(rows: data.rows),
          ],
        );
      },
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int totalRepeats;

  const _StatsHeader({required this.totalRepeats});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${AppStrings.teacherStatsTotalRepeats}: '
      '$totalRepeats${AppStrings.teacherStatsRepeatsUnit}',
      style: AppTypography.headingMedium.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final int totalRepeats;
  final VoidCallback onBack;

  const _BackHeader({required this.totalRepeats, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.ink),
          onPressed: onBack,
        ),
        Expanded(child: _StatsHeader(totalRepeats: totalRepeats)),
      ],
    );
  }
}
