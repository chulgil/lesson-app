import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';

/// Calendar tab showing weekly lesson schedule with Riverpod
class CalendarTab extends ConsumerWidget {
  const CalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekLessonsAsync = ref.watch(weekLessonsProvider);

    return Column(
      children: [
        // Header with week navigation
        const _WeekHeader(),

        // Day selector
        const _DaySelector(),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected day
        Expanded(
          child: weekLessonsAsync.when(
            data: (_) => const _LessonList(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(context, ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '레슨 정보를 불러오는데 실패했습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(weekLessonsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader();

  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: dayOfWeek - 1));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthFormat = DateFormat('M월', 'ko');
    final dayFormat = DateFormat('d일', 'ko');

    final isCurrentWeek = _getWeekStart(DateTime.now()) == weekStart;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous week button
          IconButton(
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.subtract(const Duration(days: 7));
            },
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondaryLight,
            ),
          ),

          // Week range
          GestureDetector(
            onTap: () {
              // Go to today
              final now = DateTime.now();
              ref.read(selectedWeekStartProvider.notifier).state =
                  _getWeekStart(now);
              ref.read(selectedDayIndexProvider.notifier).state =
                  now.weekday - 1;
            },
            child: Column(
              children: [
                Text(
                  '${monthFormat.format(weekStart)} ${dayFormat.format(weekStart)} - ${dayFormat.format(weekEnd)}',
                  style: AppTypography.headingMedium,
                ),
                if (!isCurrentWeek)
                  Text(
                    '오늘로 이동',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Next week button
          IconButton(
            onPressed: () {
              ref.read(selectedWeekStartProvider.notifier).state =
                  weekStart.add(const Duration(days: 7));
            },
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends ConsumerWidget {
  const _DaySelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final today = DateTime.now();
    final weekStart = ref.watch(selectedWeekStartProvider);
    final selectedDayIndex = ref.watch(selectedDayIndexProvider);
    final weekLessonsMapAsync = ref.watch(weekLessonsMapProvider);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
      child: Row(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = index == selectedDayIndex;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          // Check if this day has lessons
          final hasLessons = weekLessonsMapAsync.when(
            data: (map) => (map[index] ?? []).isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          );

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedDayIndexProvider.notifier).state = index,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primaryLight.withValues(alpha: 0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day name
                    Text(
                      days[index],
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),

                    // Date number
                    Text(
                      '${date.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),

                    // Lesson indicator dot
                    const SizedBox(height: AppSpacing.space1),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasLessons
                            ? (isSelected ? Colors.white : AppColors.primary)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LessonList extends ConsumerWidget {
  const _LessonList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final selectedDayIndex = ref.watch(selectedDayIndexProvider);
    final weekLessonsMapAsync = ref.watch(weekLessonsMapProvider);
    final selectedDate = weekStart.add(Duration(days: selectedDayIndex));
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    final lessons = weekLessonsMapAsync.when(
      data: (map) => map[selectedDayIndex] ?? [],
      loading: () => <Lesson>[],
      error: (_, __) => <Lesson>[],
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weekLessonsProvider);
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(selectedDate),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '${lessons.length}개 레슨',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Lessons
            Expanded(
              child: lessons.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      itemCount: lessons.length + 1, // +1 for add button
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, index) {
                        if (index == lessons.length) {
                          return _buildAddLessonButton(context);
                        }
                        return _LessonTimeCard(lesson: lessons[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '예정된 레슨이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          _buildAddLessonButton(context),
        ],
      ),
    );
  }

  Widget _buildAddLessonButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.push('/lessons/add');
      },
      icon: const Icon(Icons.add),
      label: const Text('레슨 추가'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _LessonTimeCard extends StatelessWidget {
  final Lesson lesson;

  const _LessonTimeCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
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
        child: Row(
          children: [
            // Time bar with status color
            Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLarge),
                  bottomLeft: Radius.circular(AppSpacing.radiusLarge),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Row(
                  children: [
                    // Time column
                    SizedBox(
                      width: 56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.startTime,
                            style: AppTypography.headingSmall,
                          ),
                          Text(
                            '${lesson.duration}분',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: AppSpacing.space3),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.borderLight,
                    ),

                    const SizedBox(width: AppSpacing.space3),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Student avatar
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  lesson.studentName.isNotEmpty
                                      ? lesson.studentName[0]
                                      : '?',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Flexible(
                                child: Text(
                                  lesson.studentName,
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lesson.instrument,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          if (lesson.pieces.isNotEmpty)
                            Text(
                              lesson.pieces.first.displayName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Status badge
                    if (lesson.status != LessonStatus.scheduled)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.space2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lesson.status.label,
                            style: AppTypography.caption.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Arrow
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (lesson.status) {
      case LessonStatus.scheduled:
        return AppColors.primary;
      case LessonStatus.completed:
        return AppColors.practiceGood;
      case LessonStatus.cancelled:
        return AppColors.textTertiaryLight;
      case LessonStatus.noShow:
        return AppColors.error;
    }
  }
}
