import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../lessons/presentation/providers/lesson_confirmation_provider.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../lessons/presentation/providers/lesson_stats_provider.dart';
import '../../../schedule/presentation/providers/unified_lesson_request_providers.dart';
import '../../../subscription/subscription_facade.dart';
import 'assignment_summary_section.dart';
import 'getting_started_card.dart';
import 'lesson_card.dart';
import 'lesson_request_section.dart';
import 'schedule_change_request_section.dart';
import 'urgent_alert_zone.dart';

/// Dashboard Tab - information hierarchy: urgent → today → trends → tools.
class DashboardTab extends ConsumerWidget {
  final VoidCallback onViewAllLessons;

  const DashboardTab({super.key, required this.onViewAllLessons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final teacherId = ref.watch(currentUserIdProvider);
    final unpaidSummaryAsync = ref.watch(unpaidSummaryProvider(teacherId));
    final needsConfirmationAsync = ref.watch(
      lessonsNeedingConfirmationProvider,
    );

    // Get today's lessons
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayLessons = lessonsAsync.whenData((lessons) {
      return lessons.where((lesson) {
          final lessonDate = lesson.date;
          return lessonDate.year == today.year &&
              lessonDate.month == today.month &&
              lessonDate.day == today.day;
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(lessonsProvider);
        ref.invalidate(lessonStatsProvider);
        ref.invalidate(unpaidSummaryProvider(teacherId));
        ref.invalidate(pendingBookingsCountProvider(teacherId));
        ref.invalidate(todayRequestsProvider(teacherId));
        ref.invalidate(expiringSoonSubscriptionsProvider);
        ref.invalidate(expiredSubscriptionsProvider);
        ref.invalidate(lessonsNeedingConfirmationProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, ref),

            const SizedBox(height: AppSpacing.space5),

            // Getting Started Guide (shown when 0 students)
            const GettingStartedCard(),

            // ── 1순위: 긴급 알림 존 ──────────────────────────
            UrgentAlertZone(
              teacherId: teacherId,
              unpaidSummary: unpaidSummaryAsync,
              needsConfirmation: needsConfirmationAsync,
            ),

            // ── 2순위: 오늘 ─────────────────────────────────
            _buildStatsRow(context, todayLessons, lessonStatsAsync),

            const SizedBox(height: AppSpacing.space6),

            // Today's Lessons Section
            _buildTodayLessonsHeader(context, todayLessons),
            const SizedBox(height: AppSpacing.space3),

            todayLessons.when(
              data: (lessons) => _buildLessonsList(context, lessons),
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.space4),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (error, _) => _buildErrorCard('레슨을 불러올 수 없습니다'),
            ),

            const SizedBox(height: AppSpacing.space6),

            // ── 이벤트: 대응 필요 (오늘 레슨 바로 아래) ──────────
            LessonRequestSection(userId: teacherId),

            const SizedBox(height: AppSpacing.space6),

            ScheduleChangeRequestSection(teacherId: teacherId),

            const SizedBox(height: AppSpacing.space6),

            const AssignmentSummarySection(),

            const SizedBox(height: AppSpacing.space6),

            // ── 하단: 통계 링크 ─────────────────────────────
            _buildAnalyticsLink(context),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Lessonaza',
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: '알림',
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
    AsyncValue<Map<String, int>> lessonStatsAsync,
  ) {
    final todayCard = todayLessons.when(
      data:
          (lessons) => StatCard(
            title: '오늘 레슨',
            value: '${lessons.length}회',
            color: AppColors.primary,
            icon: Icons.today,
            onTap: onViewAllLessons,
          ),
      loading:
          () => StatCard(
            title: '오늘 레슨',
            value: '-',
            color: AppColors.primary,
            icon: Icons.today,
          ),
      error:
          (_, __) =>
              StatCard(title: '오늘 레슨', value: '-', color: AppColors.primary),
    );

    final monthCard = lessonStatsAsync.when(
      data:
          (stats) => StatCard(
            title: '이번 달',
            value: '${stats['completed'] ?? 0}회',
            color: AppColors.primary,
            icon: Icons.check_circle_outline,
            onTap: () => context.push(AppRoutes.analytics),
          ),
      loading:
          () => StatCard(
            title: '이번 달',
            value: '-',
            color: AppColors.primary,
            icon: Icons.check_circle_outline,
          ),
      error:
          (_, __) =>
              StatCard(title: '이번 달', value: '-', color: AppColors.primary),
    );

    return StatCardRow(cards: [todayCard, monthCard]);
  }

  Widget _buildTodayLessonsHeader(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
  ) {
    final lessonCount = todayLessons.valueOrNull?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 20,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text('오늘의 레슨', style: AppTypography.headingMedium),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '($lessonCount)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        if (lessonCount > 0)
          TextButton(
            onPressed: () => context.push(AppRoutes.bulkFeedback),
            child: Text(
              '일괄 피드백',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
        if (lessonCount > 3)
          TextButton.icon(
            onPressed: onViewAllLessons,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('전체보기'),
          ),
      ],
    );
  }

  Widget _buildLessonsList(BuildContext context, List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.event_available, color: AppColors.textTertiaryLight),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  '오늘 예정된 레슨이 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.addLesson),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('레슨 추가'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasMore = lessons.length > 3;
    final displayLessons = hasMore ? lessons.take(3).toList() : lessons;

    return Column(
      children: [
        ...displayLessons.map((lesson) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: LessonCard(
              lesson: lesson,
              onTap:
                  () => context.push(
                    AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
                  ),
            ),
          );
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: OutlinedButton(
              onPressed: onViewAllLessons,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: BorderSide(color: AppColors.borderLight),
              ),
              child: Text(
                '${lessons.length - 3}개 레슨 더보기',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsLink(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push(AppRoutes.analytics),
        icon: Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
        label: Text(
          '통계 더보기',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.space3),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
