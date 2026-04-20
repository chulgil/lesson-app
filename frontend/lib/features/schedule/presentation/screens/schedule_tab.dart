import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/instrument_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../student_home/presentation/screens/student_lessons_tab.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../subscription/presentation/widgets/subscription_badge.dart';
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Text(
            '스케줄',
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 3-segment view mode toggle
          _ViewModeToggle(
            currentMode: viewMode,
            onChanged: (mode) {
              ref.read(scheduleViewModeProvider.notifier).setMode(mode);
            },
          ),
          const SizedBox(width: AppSpacing.space2),
          IconButton(
            onPressed: () => _navigateToAddLesson(context, ref),
            icon: const Icon(Icons.add),
            tooltip: '레슨 추가',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(
    WidgetRef ref,
    DateTime selectedDate,
    int lessonCount,
    LessonSortType sortType,
  ) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');
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
            dateFormat.format(selectedDate),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '오늘',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '$lessonCount개 레슨',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
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
                              color: AppColors.primary,
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
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textSecondaryLight,
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

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      itemCount: dayLessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        return _LessonTimeCard(
          lesson: dayLessons[index],
          selectedDate: selectedDate,
        );
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

class _LessonTimeCard extends ConsumerWidget {
  final Lesson lesson;
  final DateTime selectedDate;

  const _LessonTimeCard({required this.lesson, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScheduled =
        lesson.displayStatus == LessonStatus.scheduled ||
        lesson.displayStatus == LessonStatus.reschedulePending;

    final card = _buildCard(context, ref);

    if (!isScheduled) return card;

    return Dismissible(
      key: ValueKey('lesson-swipe-${lesson.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe → Complete
          return await _showConfirmDialog(
            context,
            ref,
            title: '레슨 완료',
            message: '${lesson.studentName} 레슨을 완료 처리하시겠습니까?',
            confirmLabel: '완료',
            confirmColor: AppColors.success,
            onConfirm: () async {
              final updated = lesson.copyWith(status: LessonStatus.completed);
              await ref
                  .read(lessonsNotifierProvider.notifier)
                  .updateLesson(updated);
            },
          );
        } else {
          // Left swipe → Cancel
          return await _showConfirmDialog(
            context,
            ref,
            title: '레슨 취소',
            message: '${lesson.studentName} 레슨을 취소하시겠습니까?',
            confirmLabel: '취소',
            confirmColor: AppColors.error,
            onConfirm: () async {
              await ref
                  .read(lessonsNotifierProvider.notifier)
                  .cancelLesson(lesson.id);
            },
          );
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSpacing.space2),
            Text(
              '완료',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space5),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '취소',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.space2),
            Icon(Icons.cancel, color: Colors.white),
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
      return false; // Don't dismiss the widget, let the state change handle it
    }
    return false;
  }

  Widget _buildCard(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isPastDay = selDay.isBefore(today);
    final isToday = selDay.isAtSameMomentAs(today);

    // Instrument-based color (aligned with grid/timeline views)
    final instrumentColors = InstrumentColors.getColor(lesson.instrument);

    final Color cardBgColor;
    final Color borderColor;

    if (lesson.displayStatus == LessonStatus.completed || isPastDay) {
      // Past/completed → muted grey (same as grid view)
      cardBgColor = AppColors.scheduleMutedBackground;
      borderColor = AppColors.scheduleMutedAccent;
    } else if (isToday) {
      // Today → vivid instrument colors
      cardBgColor = instrumentColors.background;
      borderColor = instrumentColors.accent;
    } else {
      // Future → softened instrument colors (50% lerp toward white)
      cardBgColor = Color.lerp(instrumentColors.background, Colors.white, 0.5)!;
      borderColor = instrumentColors.accent.withValues(alpha: 0.45);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.lessonDetail.replaceFirst(':id', lesson.id));
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              // Time column (fixed width)
              SizedBox(
                width: 56,
                child: Text(
                  lesson.startTime,
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        (isPastDay ||
                                lesson.displayStatus == LessonStatus.completed)
                            ? AppColors.textTertiaryLight
                            : null,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Info column (flexible)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.studentName} · ${lesson.instrument}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            (isPastDay ||
                                    lesson.displayStatus ==
                                        LessonStatus.completed)
                                ? AppColors.textSecondaryLight
                                : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildBadgesRow(ref),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Status (fixed width)
              SizedBox(
                width: 36,
                child: Text(
                  _getStatusLabel(),
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),

              const SizedBox(width: AppSpacing.space1),

              // Arrow
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return '예정';
      case LessonStatus.completed:
        return '완료';
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return '취소';
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return '결석';
    }
  }

  Color _getStatusColor() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return AppColors.primary;
      case LessonStatus.completed:
        return AppColors.success;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return AppColors.textTertiaryLight;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return AppColors.error;
    }
  }

  /// Build context badge (🏫/👤) and subscription badge row.
  Widget _buildBadgesRow(WidgetRef ref) {
    final memberships =
        ref
            .watch(activeStudentMembershipsProvider(lesson.studentId))
            .valueOrNull;
    final subscriptions =
        ref
            .watch(activeStudentSubscriptionsProvider(lesson.studentId))
            .valueOrNull;

    // Context badge from lesson class
    Widget? contextBadge;
    if (memberships != null && memberships.isNotEmpty) {
      final lessonClass =
          ref
              .watch(lessonClassProvider(memberships.first.lessonClassId))
              .valueOrNull;
      if (lessonClass != null) {
        final isAcademy = lessonClass.type == LessonClassType.academy;
        contextBadge = Text(
          isAcademy ? '🏫 ${lessonClass.name}' : '👤 개인레슨',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    final subscription =
        (subscriptions?.isNotEmpty == true) ? subscriptions!.first : null;

    if (contextBadge == null && subscription == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (contextBadge != null) Flexible(child: contextBadge),
          if (contextBadge != null && subscription != null)
            const SizedBox(width: 6),
          if (subscription != null)
            SubscriptionBadge(subscription: subscription, showIcon: false),
        ],
      ),
    );
  }
}

/// 3-segment toggle for switching between schedule view modes.
class _ViewModeToggle extends StatelessWidget {
  final ScheduleViewMode currentMode;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ViewModeToggle({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scheduleMutedBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
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
                    borderRadius: BorderRadius.circular(6),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                            : null,
                  ),
                  child: Icon(
                    _getIcon(mode),
                    size: 16,
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
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
