import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../../shared/widgets/collapsible_calendar.dart';

/// State provider for calendar expansion
final calendarExpandedProvider = StateProvider<bool>((ref) => true);

/// State provider for selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Calendar tab showing lesson schedule with collapsible month/week calendar
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastScrollOffset;
    final isExpanded = ref.read(calendarExpandedProvider);

    // Only react to significant scroll movements
    if (delta.abs() > 15) {
      if (delta > 0 && isExpanded) {
        // Scrolling down - collapse calendar
        ref.read(calendarExpandedProvider.notifier).state = false;
      } else if (delta < 0 && !isExpanded && offset < 100) {
        // Scrolling up near top - expand calendar
        ref.read(calendarExpandedProvider.notifier).state = true;
      }
      _lastScrollOffset = offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(calendarExpandedProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    // Get marked dates (dates with lessons)
    final markedDates = lessonsAsync.whenOrNull(
      data: (lessons) => lessons
          .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
          .toSet(),
    );

    return Column(
      children: [
        // Collapsible Calendar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: CollapsibleCalendar(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
            isExpanded: isExpanded,
            markedDates: markedDates,
            onToggleExpand: () {
              ref.read(calendarExpandedProvider.notifier).state = !isExpanded;
            },
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list
        Expanded(
          child: lessonsAsync.when(
            data: (lessons) => _LessonList(
              selectedDate: selectedDate,
              lessons: lessons,
              scrollController: _scrollController,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(ref, error),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
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
              ref.invalidate(lessonsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  final DateTime selectedDate;
  final List<Lesson> lessons;
  final ScrollController scrollController;

  const _LessonList({
    required this.selectedDate,
    required this.lessons,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Filter lessons for selected date
    final dayLessons = lessons.where((l) =>
        l.date.year == selectedDate.year &&
        l.date.month == selectedDate.month &&
        l.date.day == selectedDate.day).toList();

    // Sort by time
    dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh is handled by parent
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date title
            Row(
              children: [
                Text(
                  dateFormat.format(selectedDate),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (_isToday(selectedDate)) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
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
                  '${dayLessons.length}개 레슨',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Lessons
            Expanded(
              child: dayLessons.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: dayLessons.length + 1, // +1 for add button
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, index) {
                        if (index == dayLessons.length) {
                          return _buildAddLessonButton(context);
                        }
                        return _LessonTimeCard(lesson: dayLessons[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
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
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildAddLessonButton(BuildContext context) {
    // Calculate next hour from now
    final now = DateTime.now();
    int nextHour = now.hour + 1;
    if (nextHour > 23) nextHour = 9; // Default to 9 AM if past 11 PM

    // Format selected date as query param
    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return OutlinedButton.icon(
      onPressed: () {
        context.push('/lessons/add?date=$dateStr&hour=$nextHour');
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
