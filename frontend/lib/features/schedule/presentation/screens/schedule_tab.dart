import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../home/presentation/widgets/lesson_card.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../student_home/presentation/screens/student_lessons_tab.dart';
import '../providers/schedule_view_mode_provider.dart';
import '../widgets/compact_week_strip.dart';
import '../widgets/schedule_timeline_view.dart';
import '../widgets/schedule_weekly_grid_view.dart';

/// State provider for teacher selected date
final teacherSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// State provider for teacher lesson sort type
final teacherLessonSortTypeProvider = StateProvider<LessonSortType>(
  (ref) => LessonSortType.timeAsc,
);

/// Calendar tab with WeekCalendar and lesson list
class ScheduleTab extends ConsumerWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(teacherSelectedDateProvider);
    final sortType = ref.watch(teacherLessonSortTypeProvider);
    final viewMode = ref.watch(scheduleViewModeProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    return Column(
      children: [
        // Header: title + view toggle + add button
        _buildHeader(context, ref),

        // Calendar: unified CompactWeekStrip for all view modes
        // §7.126 — 모든 모드 헤더 동일 사이즈 (screenPadding 좌우).
        // 주간 그리드는 시간 라벨 폭(16) 을 헤더 좌측 패딩 영역에
        // 흡수시켜 정렬 (schedule_weekly_grid_view.dart §7.126 참조).
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: lessonsAsync.when(
            data: (lessons) {
              final lessonDates =
                  lessons
                      .map(
                        (l) => DateTime(l.date.year, l.date.month, l.date.day),
                      )
                      .toSet();
              return CompactWeekStrip(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(teacherSelectedDateProvider.notifier).state = date;
                },
                markerDates: lessonDates,
              );
            },
            loading:
                () => CompactWeekStrip(
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    ref.read(teacherSelectedDateProvider.notifier).state = date;
                  },
                ),
            error:
                (_, __) => CompactWeekStrip(
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    ref.read(teacherSelectedDateProvider.notifier).state = date;
                  },
                ),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Content: switches between list view, timeline view, and weekly grid
        // Timeline/weekly grid support horizontal swipe for day/week navigation
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd:
                (viewMode == ScheduleViewMode.list)
                    ? null
                    : (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 100) return;
                      final delta =
                          viewMode == ScheduleViewMode.timeline
                              ? const Duration(
                                days: 1,
                              ) // day-by-day for timeline
                              : const Duration(
                                days: 7,
                              ); // week-by-week for grid
                      final newDate =
                          velocity > 0
                              ? selectedDate.subtract(delta)
                              : selectedDate.add(delta);
                      ref.read(teacherSelectedDateProvider.notifier).state =
                          newDate;
                    },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  viewMode == ScheduleViewMode.weeklyGrid
                      ? ScheduleWeeklyGridView(
                        key: const ValueKey(ScheduleViewMode.weeklyGrid),
                        selectedDate: selectedDate,
                      )
                      : _buildViewContent(
                        key: ValueKey(viewMode),
                        lessonsAsync: lessonsAsync,
                        selectedDate: selectedDate,
                        sortType: sortType,
                        viewMode: viewMode,
                        ref: ref,
                        context: context,
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewContent({
    Key? key,
    required AsyncValue<List<Lesson>> lessonsAsync,
    required DateTime selectedDate,
    required LessonSortType sortType,
    required ScheduleViewMode viewMode,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    return lessonsAsync.when(
      data: (lessons) {
        // Filter lessons for selected date
        final dayLessons =
            lessons
                .where(
                  (l) =>
                      l.date.year == selectedDate.year &&
                      l.date.month == selectedDate.month &&
                      l.date.day == selectedDate.day,
                )
                .toList();

        // Sort lessons
        switch (sortType) {
          case LessonSortType.timeAsc:
            dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
          case LessonSortType.nameAsc:
            dayLessons.sort((a, b) => a.studentName.compareTo(b.studentName));
        }

        if (viewMode == ScheduleViewMode.timeline) {
          return ScheduleTimelineView(
            key: key,
            lessons: dayLessons,
            selectedDate: selectedDate,
          );
        }

        // List view (default)
        return Column(
          key: key,
          children: [
            // Date header with count and sort
            _buildDateHeader(ref, selectedDate, dayLessons.length, sortType),
            const SizedBox(height: AppSpacing.space3),
            Expanded(
              child: _buildLessonList(context, dayLessons, selectedDate),
            ),
          ],
        );
      },
      loading:
          () => Column(
            children: [
              _buildDateHeader(ref, selectedDate, 0, sortType),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
      error:
          (error, _) => Column(
            children: [
              _buildDateHeader(ref, selectedDate, 0, sortType),
              Expanded(child: _buildErrorState(ref, error)),
            ],
          ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(scheduleViewModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          // ── Masthead: "SCHEDULE" eyebrow + 레슨 추가 IconButton ──
          NotebookMasthead(
            eyebrow: 'SCHEDULE',
            meta: _volumeIssueString(DateTime.now()),
            trailing: IconButton(
              onPressed: () => _navigateToAddLesson(context, ref),
              icon: const Icon(Icons.add),
              tooltip: '레슨 추가',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: AppColors.paper,
              ),
            ),
          ),
          // ── Programme Title — "스케줄" Playfair ──
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Programme of Schedule',
                  style: NotebookTypography.mastheadLabel,
                ),
                const SizedBox(height: 4),
                Text('스케줄', style: NotebookTypography.masthead),
                const SizedBox(height: AppSpacing.space3),
                const ThinRule(),
              ],
            ),
          ),
          // ── View Mode Toggle Row — 독립 배치 ──
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ViewModeToggle(
                  currentMode: viewMode,
                  onChanged: (mode) {
                    ref.read(scheduleViewModeProvider.notifier).setMode(mode);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Notebook meta: "VOL. IV · NO. 23" 형식.
  String _volumeIssueString(DateTime now) {
    return 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}';
  }

  Widget _buildDateHeader(
    WidgetRef ref,
    DateTime selectedDate,
    int lessonCount,
    LessonSortType sortType,
  ) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            formatDateMDWithDayLong(selectedDate),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              // Notebook × Score: 각진 뱃지 (§7.113 매트릭스 — 컨테이너 bg zero)
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
              ),
              // "오늘" = 시스템 마지널리아 → Gaegu handEmphasis (§1.1 #4).
              child: Text('오늘', style: NotebookTypography.handEmphasis),
            ),
          ],
          const Spacer(),
          Text(
            '$lessonCount개 레슨',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          _buildSortDropdown(ref, sortType),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(WidgetRef ref, LessonSortType sortType) {
    return PopupMenuButton<LessonSortType>(
      onSelected: (value) {
        ref.read(teacherLessonSortTypeProvider.notifier).state = value;
      },
      itemBuilder:
          (context) =>
              LessonSortType.values
                  .map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          if (type == sortType)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.paperAccent,
                            )
                          else
                            const SizedBox(width: AppSpacing.space4),
                          const SizedBox(width: AppSpacing.space2),
                          Text(type.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sortType.displayName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.inkSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    List<Lesson> dayLessons,
    DateTime selectedDate,
  ) {
    if (dayLessons.isEmpty) {
      return _buildEmptyState();
    }

    // Notebook × Score: 갭 + 둥근카드 + 그림자 패턴을 제거하고, LessonCard 의
    // 하단 1px 잉크 라인이 항목 구분을 담당하도록 ListView.builder 로 전환
    // (§7.X 리스트 항목 = 악보 프로그램 행 — ThinRule 경계·paper 질감 일관).
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: dayLessons.length,
      itemBuilder: (context, index) {
        return _SwipeableLessonCard(lesson: dayLessons[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.event_available,
      title: '예정된 레슨이 없습니다',
      scrollable: true,
    );
  }

  void _navigateToAddLesson(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.read(teacherSelectedDateProvider);
    final now = DateTime.now();
    int nextHour = now.hour + 1;
    if (nextHour > 23) nextHour = 9;

    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    context.push('${AppRoutes.addLesson}?date=$dateStr&hour=$nextHour');
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: '레슨 정보를 불러오는데 실패했습니다',
      actionLabel: '다시 시도',
      actionIcon: Icons.refresh,
      onAction: () => ref.invalidate(lessonsProvider),
    );
  }
}

/// Notebook × Score: 공용 `LessonCard` 를 재사용하고, 교사만 예정 레슨에 한해
/// 좌/우 스와이프로 완료/취소 액션을 노출하도록 Dismissible 로 래핑.
/// 카드 본체 디자인(좌 3px 상태선 + 하단 1px 잉크 라인)은 LessonCard 에서 관리.
class _SwipeableLessonCard extends ConsumerWidget {
  final Lesson lesson;

  const _SwipeableLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScheduled =
        lesson.displayStatus == LessonStatus.scheduled ||
        lesson.displayStatus == LessonStatus.reschedulePending;

    final card = LessonCard(
      lesson: lesson,
      onTap:
          () => context.push(
            AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
          ),
    );

    if (!isScheduled) return card;

    return Dismissible(
      key: ValueKey('lesson-swipe-${lesson.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return await _showConfirmDialog(
            context,
            ref,
            title: '레슨 완료',
            message: '${lesson.studentName} 레슨을 완료 처리하시겠습니까?',
            confirmLabel: '완료',
            confirmColor: AppColors.paperOk,
            onConfirm: () async {
              final updated = lesson.copyWith(status: LessonStatus.completed);
              await ref
                  .read(lessonsNotifierProvider.notifier)
                  .updateLesson(updated);
            },
          );
        } else {
          return await _showConfirmDialog(
            context,
            ref,
            title: '레슨 취소',
            message: '${lesson.studentName} 레슨을 취소하시겠습니까?',
            confirmLabel: '취소',
            confirmColor: AppColors.paperAccent,
            onConfirm: () async {
              await ref
                  .read(lessonsNotifierProvider.notifier)
                  .cancelLesson(lesson.id);
            },
          );
        }
      },
      // Notebook × Score: 스와이프 배경도 paper 톤 + 둥근 모서리 제거로
      // 카드 경계(좌 3px · 하단 1px)와 같은 평면 질감을 유지.
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.space5),
        color: AppColors.paperOk,
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.paper),
            SizedBox(width: AppSpacing.space2),
            Text(
              '완료',
              style: TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space5),
        color: AppColors.paperAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              '취소',
              style: TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.space2),
            Icon(Icons.cancel, color: AppColors.paper),
          ],
        ),
      ),
      child: card,
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('돌아가기'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lesson.studentName} 레슨이 $confirmLabel되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return false;
  }
}

/// 3-segment toggle for switching between schedule view modes.
class _ViewModeToggle extends StatelessWidget {
  final ScheduleViewMode currentMode;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ViewModeToggle({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 각진 토글 + 그림자 제거 (§7.113/§7.114)
    // 종이 위 직사각 세그먼트 — 선택 시 paper 배경으로 대비만 유지
    return Container(
      decoration: const BoxDecoration(color: AppColors.scheduleMutedBackground),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            ScheduleViewMode.values.map((mode) {
              final isSelected = mode == currentMode;
              return GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                  child: Icon(
                    _getIcon(mode),
                    size: 16,
                    color:
                        isSelected
                            ? AppColors.paperAccent
                            : AppColors.inkTertiary,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  IconData _getIcon(ScheduleViewMode mode) {
    switch (mode) {
      case ScheduleViewMode.list:
        return Icons.format_list_bulleted;
      case ScheduleViewMode.timeline:
        return Icons.view_day;
      case ScheduleViewMode.weeklyGrid:
        return Icons.grid_view;
    }
  }
}
