import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/week_calendar_widget.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../student_home/presentation/screens/student_lessons_tab.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/widgets/subscription_badge.dart';

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
    final lessonsAsync = ref.watch(lessonsProvider);

    return Column(
      children: [
        // Header: title + add button
        _buildHeader(context, ref),

        // WeekCalendarWidget
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
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
              return WeekCalendarWidget(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(teacherSelectedDateProvider.notifier).state = date;
                },
                lessonDates: lessonDates,
              );
            },
            loading:
                () => WeekCalendarWidget(
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    ref.read(teacherSelectedDateProvider.notifier).state = date;
                  },
                ),
            error:
                (_, __) => WeekCalendarWidget(
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    ref.read(teacherSelectedDateProvider.notifier).state = date;
                  },
                ),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Content: date header + lesson list
        Expanded(
          child: lessonsAsync.when(
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
                  dayLessons.sort(
                    (a, b) => a.studentName.compareTo(b.studentName),
                  );
              }

              return Column(
                children: [
                  // Date header with count and sort
                  _buildDateHeader(
                    ref,
                    selectedDate,
                    dayLessons.length,
                    sortType,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Expanded(child: _buildLessonList(context, dayLessons)),
                ],
              );
            },
            loading:
                () => Column(
                  children: [
                    _buildDateHeader(ref, selectedDate, 0, sortType),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
            error:
                (error, _) => Column(
                  children: [
                    _buildDateHeader(ref, selectedDate, 0, sortType),
                    Expanded(child: _buildErrorState(ref, error)),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
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
            const SizedBox(width: 8),
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
          const SizedBox(width: 12),
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
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
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

  Widget _buildLessonList(BuildContext context, List<Lesson> dayLessons) {
    if (dayLessons.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: dayLessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        return _LessonTimeCard(lesson: dayLessons[index]);
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

    context.push('/lessons/add?date=$dateStr&hour=$nextHour');
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

  const _LessonTimeCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border(left: BorderSide(color: _getStatusColor(), width: 4)),
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
          context.push('/lessons/${lesson.id}');
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
    switch (lesson.status) {
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
    switch (lesson.status) {
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
