import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';

/// Quick feedback student selection screen
/// Shows today's lesson students first, then recent lesson students
class QuickFeedbackStudentList extends ConsumerStatefulWidget {
  const QuickFeedbackStudentList({super.key});

  @override
  ConsumerState<QuickFeedbackStudentList> createState() =>
      _QuickFeedbackStudentListState();
}

class _QuickFeedbackStudentListState
    extends ConsumerState<QuickFeedbackStudentList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('피드백 보내기'),
      ),
      body: lessonsAsync.when(
        data: (lessons) => _buildBody(lessons),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            '데이터를 불러오는데 실패했습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Lesson> allLessons) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Separate today's lessons and recent lessons
    final todayLessons = allLessons
        .where((l) =>
            DateTime(l.date.year, l.date.month, l.date.day) == today)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final todayStudentIds = todayLessons.map((l) => l.studentId).toSet();

    // Recent lessons: not today, unique by student, sorted by date desc
    final recentByStudent = <String, Lesson>{};
    final sortedPast = allLessons
        .where((l) =>
            DateTime(l.date.year, l.date.month, l.date.day).isBefore(today) &&
            !todayStudentIds.contains(l.studentId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final lesson in sortedPast) {
      recentByStudent.putIfAbsent(lesson.studentId, () => lesson);
    }
    final recentLessons = recentByStudent.values.toList();

    // Apply search filter
    final filteredToday = _filterLessons(todayLessons);
    final filteredRecent = _filterLessons(recentLessons);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: '학생 검색...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              filled: true,
              fillColor: AppColors.surfaceSecondaryLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
            ),
          ),
        ),

        // Student list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            children: [
              if (filteredToday.isNotEmpty) ...[
                _buildSectionHeader('오늘 레슨'),
                const SizedBox(height: AppSpacing.space2),
                ...filteredToday.map(_buildTodayLessonTile),
                const SizedBox(height: AppSpacing.space4),
              ],
              if (filteredRecent.isNotEmpty) ...[
                _buildSectionHeader('최근 레슨'),
                const SizedBox(height: AppSpacing.space2),
                ...filteredRecent.map(_buildRecentLessonTile),
              ],
              if (filteredToday.isEmpty && filteredRecent.isEmpty)
                _buildEmptyState(),
            ],
          ),
        ),
      ],
    );
  }

  List<Lesson> _filterLessons(List<Lesson> lessons) {
    if (_searchQuery.isEmpty) return lessons;
    final query = _searchQuery.toLowerCase();
    return lessons
        .where((l) =>
            l.studentName.toLowerCase().contains(query) ||
            l.instrument.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildTodayLessonTile(Lesson lesson) {
    final isCompleted = lesson.displayStatus == LessonStatus.completed;
    final hasFeedback =
        lesson.feedback != null && lesson.feedback!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: ListTile(
        onTap: () => context.push(
          AppRoutes.quickFeedback.replaceFirst(':id', lesson.id),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: BorderSide(color: AppColors.borderLight),
        ),
        tileColor: AppColors.surfaceLight,
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? AppColors.practiceGood.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.schedule,
            color: isCompleted ? AppColors.practiceGood : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          '${lesson.studentName} · ${lesson.instrument}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${lesson.startTime} 레슨 (${isCompleted ? "완료" : "예정"})',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        trailing: hasFeedback
            ? Icon(Icons.check, color: AppColors.practiceGood, size: 20)
            : Icon(Icons.edit_outlined,
                color: AppColors.textTertiaryLight, size: 20),
      ),
    );
  }

  Widget _buildRecentLessonTile(Lesson lesson) {
    final hasFeedback =
        lesson.feedback != null && lesson.feedback!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: ListTile(
        onTap: () => context.push(
          AppRoutes.quickFeedback.replaceFirst(':id', lesson.id),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          side: BorderSide(color: AppColors.borderLight),
        ),
        tileColor: AppColors.surfaceLight,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceSecondaryLight,
          child: Icon(
            Icons.person_outline,
            color: AppColors.textSecondaryLight,
            size: 20,
          ),
        ),
        title: Text(
          '${lesson.studentName} · ${lesson.instrument}',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${lesson.date.month}월 ${lesson.date.day}일 마지막 레슨',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        trailing: hasFeedback
            ? Icon(Icons.check, color: AppColors.practiceGood, size: 20)
            : Icon(Icons.edit_outlined,
                color: AppColors.textTertiaryLight, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            _searchQuery.isEmpty
                ? '피드백을 보낼 레슨이 없습니다'
                : '검색 결과가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
