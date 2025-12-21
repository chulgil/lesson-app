import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Student lessons tab showing upcoming and past lessons
class StudentLessonsTab extends StatefulWidget {
  const StudentLessonsTab({super.key});

  @override
  State<StudentLessonsTab> createState() => _StudentLessonsTabState();
}

class _StudentLessonsTabState extends State<StudentLessonsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space4,
            AppSpacing.screenPadding,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('내 레슨', style: AppTypography.headingLarge),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: '캘린더 보기',
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondaryLight,
            labelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: '예정된 레슨'),
              Tab(text: '지난 레슨'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UpcomingLessonsView(),
              _PastLessonsView(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Upcoming lessons view
class _UpcomingLessonsView extends StatelessWidget {
  const _UpcomingLessonsView();

  @override
  Widget build(BuildContext context) {
    final upcomingLessons = _mockUpcomingLessons();

    if (upcomingLessons.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: upcomingLessons.length,
      itemBuilder: (context, index) {
        return _LessonCard(
          lesson: upcomingLessons[index],
          isUpcoming: true,
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
          const SizedBox(height: AppSpacing.space2),
          Text(
            '선생님이 레슨을 예약하면 여기에 표시됩니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Past lessons view
class _PastLessonsView extends StatelessWidget {
  const _PastLessonsView();

  @override
  Widget build(BuildContext context) {
    final pastLessons = _mockPastLessons();

    if (pastLessons.isEmpty) {
      return _buildEmptyState();
    }

    // Group lessons by month
    final groupedLessons = <String, List<_StudentLessonData>>{};
    for (final lesson in pastLessons) {
      final monthKey = DateFormat('yyyy년 M월', 'ko').format(lesson.dateTime);
      groupedLessons.putIfAbsent(monthKey, () => []).add(lesson);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: groupedLessons.length,
      itemBuilder: (context, index) {
        final monthKey = groupedLessons.keys.elementAt(index);
        final lessons = groupedLessons[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppSpacing.space4),
            Text(
              monthKey,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            ...lessons.map((lesson) => _LessonCard(
                  lesson: lesson,
                  isUpcoming: false,
                )),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '지난 레슨이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson card widget
class _LessonCard extends StatelessWidget {
  final _StudentLessonData lesson;
  final bool isUpcoming;

  const _LessonCard({
    required this.lesson,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final daysUntil = lesson.dateTime.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
        child: Column(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Row(
                children: [
                  // Date column
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isUpcoming
                          ? AppColors.primaryLight.withValues(alpha: 0.2)
                          : AppColors.surfaceSecondaryLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lesson.dateTime.day}',
                          style: AppTypography.headingMedium.copyWith(
                            color:
                                isUpcoming ? AppColors.primary : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          DateFormat('E', 'ko').format(lesson.dateTime),
                          style: AppTypography.caption.copyWith(
                            color: isUpcoming
                                ? AppColors.primary
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.space3),

                  // Info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lesson.teacherName,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
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
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textTertiaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${timeFormat.format(lesson.dateTime)} (${lesson.duration}분)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // D-day or status
                  if (isUpcoming)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: daysUntil <= 1
                            ? AppColors.primary
                            : AppColors.surfaceSecondaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        daysUntil == 0
                            ? '오늘'
                            : daysUntil == 1
                                ? '내일'
                                : 'D-$daysUntil',
                        style: AppTypography.caption.copyWith(
                          color: daysUntil <= 1
                              ? Colors.white
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiaryLight,
                    ),
                ],
              ),
            ),

            // Lesson content preview (for upcoming)
            if (isUpcoming && lesson.piece != null) ...[
              Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 16,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        lesson.piece!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Feedback preview (for past lessons)
            if (!isUpcoming && lesson.feedback != null) ...[
              Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        lesson.feedback!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Student lesson data model
class _StudentLessonData {
  final String id;
  final DateTime dateTime;
  final int duration;
  final String teacherName;
  final String instrument;
  final String? piece;
  final String? feedback;

  _StudentLessonData({
    required this.id,
    required this.dateTime,
    required this.duration,
    required this.teacherName,
    required this.instrument,
    this.piece,
    this.feedback,
  });
}

List<_StudentLessonData> _mockUpcomingLessons() {
  final now = DateTime.now();
  return [
    _StudentLessonData(
      id: 'lesson_upcoming_1',
      dateTime: now.add(const Duration(days: 2, hours: 2)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Allemande, Sarabande',
    ),
    _StudentLessonData(
      id: 'lesson_upcoming_2',
      dateTime: now.add(const Duration(days: 9, hours: 3)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '크로이처 에튀드 3번',
    ),
    _StudentLessonData(
      id: 'lesson_upcoming_3',
      dateTime: now.add(const Duration(days: 16, hours: 1)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
    ),
  ];
}

List<_StudentLessonData> _mockPastLessons() {
  final now = DateTime.now();
  return [
    _StudentLessonData(
      id: 'lesson_past_1',
      dateTime: now.subtract(const Duration(days: 5)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Allemande',
      feedback: '보잉이 많이 좋아졌습니다. 다음 시간에 Sarabande 시작합시다.',
    ),
    _StudentLessonData(
      id: 'lesson_past_2',
      dateTime: now.subtract(const Duration(days: 12)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '크로이처 에튀드 2번',
      feedback: '에튀드 마무리 잘 했어요. 다음 곡으로 넘어갑시다.',
    ),
    _StudentLessonData(
      id: 'lesson_past_3',
      dateTime: now.subtract(const Duration(days: 19)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: '바흐 파르티타 2번 - Chaconne',
      feedback: '샤콘느 1부 완성! 정말 대단해요.',
    ),
    _StudentLessonData(
      id: 'lesson_past_4',
      dateTime: now.subtract(const Duration(days: 40)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      piece: 'G Major 스케일, 크로이처 1번',
    ),
    _StudentLessonData(
      id: 'lesson_past_5',
      dateTime: now.subtract(const Duration(days: 47)),
      duration: 60,
      teacherName: '김선생님',
      instrument: '바이올린',
      feedback: '스케일 연습 방법 지도. 3옥타브까지 연습해오기.',
    ),
  ];
}
