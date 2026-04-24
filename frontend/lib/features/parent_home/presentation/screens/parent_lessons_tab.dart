import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Parent lessons tab for viewing child's lesson schedule
class ParentLessonsTab extends ConsumerWidget {
  const ParentLessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('레슨 일정'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Calendar view placeholder
          _buildCalendarHeader(),
          const SizedBox(height: AppSpacing.space4),

          // Upcoming lessons
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
          Text('예정된 레슨', style: NotebookTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space3),

          _LessonCard(
            lessonId: 'lesson_upcoming_1',
            date: DateTime.now().add(const Duration(days: 1)),
            startTime: '14:00',
            endTime: '15:00',
            teacherName: '김선생님',
            status: LessonStatus.confirmed,
            onTap:
                () => context.push(
                  AppRoutes.lessonDetail.replaceFirst(
                    ':id',
                    'lesson_upcoming_1',
                  ),
                ),
          ),

          const SizedBox(height: AppSpacing.space3),

          _LessonCard(
            lessonId: 'lesson_upcoming_2',
            date: DateTime.now().add(const Duration(days: 8)),
            startTime: '14:00',
            endTime: '15:00',
            teacherName: '김선생님',
            status: LessonStatus.confirmed,
            onTap:
                () => context.push(
                  AppRoutes.lessonDetail.replaceFirst(
                    ':id',
                    'lesson_upcoming_2',
                  ),
                ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Past lessons
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
          Text('지난 레슨', style: NotebookTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space3),

          _LessonCard(
            lessonId: 'lesson_1',
            date: DateTime.now().subtract(const Duration(days: 6)),
            startTime: '14:00',
            endTime: '15:00',
            teacherName: '김선생님',
            status: LessonStatus.completed,
            hasNote: true,
            onTap:
                () => context.push(
                  AppRoutes.lessonDetail.replaceFirst(':id', 'lesson_1'),
                ),
            onViewNote: () => _showLessonNoteSheet(context, 'lesson_1'),
          ),

          const SizedBox(height: AppSpacing.space3),

          _LessonCard(
            lessonId: 'lesson_2',
            date: DateTime.now().subtract(const Duration(days: 13)),
            startTime: '14:00',
            endTime: '15:00',
            teacherName: '김선생님',
            status: LessonStatus.completed,
            hasNote: true,
            onTap:
                () => context.push(
                  AppRoutes.lessonDetail.replaceFirst(':id', 'lesson_2'),
                ),
            onViewNote: () => _showLessonNoteSheet(context, 'lesson_2'),
          ),
        ],
      ),
    );
  }

  void _showLessonNoteSheet(BuildContext context, String lessonId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      const Center(
                        child: BottomSheetHandle(
                          margin: EdgeInsets.only(bottom: AppSpacing.space4),
                        ),
                      ),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Notebook × Score: 바텀시트 섹션 헤더 (§7.17/§7.27) — Playfair sectionTitle.
                          Text('레슨 노트', style: NotebookTypography.sectionTitle),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push(
                                AppRoutes.lessonDetail.replaceFirst(
                                  ':id',
                                  lessonId,
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('상세보기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // Lesson info
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.space3),
                              decoration: BoxDecoration(
                                color: AppColors.paperDark,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.inkSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.space2),
                                  Text(
                                    '12월 21일 (토) 14:00 - 15:00',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space4),

                            // Note content
                            Text(
                              '수업 내용',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              '• 스케일 연습: A장조 3옥타브 연습. 음정 안정성이 많이 향상되었습니다.\n'
                              '• 에튀드: 크로이처 No.2 마무리. 다음 주부터 No.3 시작 예정.\n'
                              '• 곡 연습: 모차르트 소나타 1악장 익스포지션 부분. 비브라토 적용 연습.',
                              style: AppTypography.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.space4),

                            // Teacher comment
                            Text(
                              '선생님 코멘트',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.space3),
                              decoration: BoxDecoration(
                                color: AppColors.paperAccentSoft.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.zero,
                                border: Border.all(
                                  color: AppColors.paperAccentSoft,
                                ),
                              ),
                              child: Text(
                                '이번 주 연습을 정말 열심히 해왔네요! 특히 스케일의 음정이 많이 안정되었어요. '
                                '다음 주까지 비브라토 연습에 집중해서 모차르트 곡에 적용해보세요. '
                                '화이팅입니다! 💪',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space4),

                            // Practice assignments
                            Text(
                              '과제',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            _buildAssignmentItem(
                              title: '스케일 연습',
                              description: 'A장조 3옥타브 (메트로놈 ♩=80)',
                              priority: 'must',
                            ),
                            _buildAssignmentItem(
                              title: '비브라토 연습',
                              description: '느린 템포로 꾸준히 연습',
                              priority: 'should',
                            ),
                            _buildAssignmentItem(
                              title: '모차르트 소나타',
                              description: '1악장 전체 암보',
                              priority: 'must',
                            ),
                            const SizedBox(height: AppSpacing.space4),

                            // Recording (if any)
                            Text(
                              '녹음',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.space3),
                              decoration: BoxDecoration(
                                color: AppColors.paperDark,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.paperAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '모차르트 소나타 녹음',
                                          style: AppTypography.bodyMedium,
                                        ),
                                        Text(
                                          '3:24',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildAssignmentItem({
    required String title,
    required String description,
    required String priority,
  }) {
    Color priorityColor;
    String priorityLabel;

    switch (priority) {
      case 'must':
        priorityColor = AppColors.paperAccent;
        priorityLabel = '필수';
        break;
      case 'should':
        priorityColor = AppColors.paperAccent;
        priorityLabel = '권장';
        break;
      default:
        priorityColor = AppColors.paperOk;
        priorityLabel = '선택';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              priorityLabel,
              style: AppTypography.captionSmall.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final now = DateTime.now();
    final monthName = formatYearMonth(now);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left),
              ),
              Text(monthName, style: AppTypography.headingSmall),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          // Mini calendar week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['일', '월', '화', '수', '목', '금', '토']
                    .map(
                      (day) => SizedBox(
                        width: 36,
                        child: Text(
                          day,
                          style: AppTypography.caption.copyWith(
                            color:
                                day == '일'
                                    ? AppColors.paperAccent
                                    : day == '토'
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: AppSpacing.space2),
          // Placeholder for calendar grid
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              '월간 캘린더 뷰',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LessonStatus { confirmed, completed, cancelled }

class _LessonCard extends StatelessWidget {
  final String lessonId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String teacherName;
  final LessonStatus status;
  final bool hasNote;
  final VoidCallback? onTap;
  final VoidCallback? onViewNote;

  const _LessonCard({
    required this.lessonId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.teacherName,
    required this.status,
    this.hasNote = false,
    this.onTap,
    this.onViewNote,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = status == LessonStatus.completed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            // Date box
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              decoration: BoxDecoration(
                color:
                    isPast
                        ? AppColors.paperDark
                        : AppColors.paperAccentSoft.withValues(alpha: 0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: AppTypography.headingMedium.copyWith(
                      color:
                          isPast
                              ? AppColors.inkSecondary
                              : AppColors.paperAccent,
                    ),
                  ),
                  Text(
                    formatWeekdayShort(date),
                    style: AppTypography.caption.copyWith(
                      color:
                          isPast
                              ? AppColors.inkTertiary
                              : AppColors.paperAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Lesson details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '정규 레슨',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isPast ? AppColors.inkSecondary : AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '$startTime - $endTime • $teacherName',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (hasNote)
              IconButton(
                onPressed: onViewNote,
                icon: Icon(Icons.note_outlined, color: AppColors.paperAccent),
                tooltip: '레슨 노트',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case LessonStatus.confirmed:
        bgColor = AppColors.paperDark;
        textColor = AppColors.paperOk;
        label = '예정';
        break;
      case LessonStatus.completed:
        bgColor = AppColors.paperDark;
        textColor = AppColors.inkSecondary;
        label = '완료';
        break;
      case LessonStatus.cancelled:
        bgColor = AppColors.paperAccentSoft;
        textColor = AppColors.paperAccent;
        label = '취소';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
