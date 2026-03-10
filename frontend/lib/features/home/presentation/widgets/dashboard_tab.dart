import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/presentation/providers/subscription_proposal_providers.dart';
import 'assignment_summary_section.dart';
import 'lesson_card.dart';
import 'urgent_actions_section.dart';

/// Dashboard Tab - core stats + urgent actions + today's lessons.
class DashboardTab extends ConsumerWidget {
  final VoidCallback onViewAllLessons;

  const DashboardTab({super.key, required this.onViewAllLessons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final teacherId = ref.watch(currentUserIdProvider);
    final unpaidSummaryAsync = ref.watch(unpaidSummaryProvider(teacherId));
    final pendingRequestsAsync = ref.watch(
      pendingLessonRequestCountProvider(teacherId),
    );
    final pendingBookingsAsync = ref.watch(
      pendingBookingsCountProvider(teacherId),
    );
    final awaitingConfirmAsync = ref.watch(
      awaitingConfirmationProposalsProvider(teacherId),
    );
    final expiringSoonAsync = ref.watch(expiringSoonSubscriptionsProvider);

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
        ref.invalidate(pendingLessonRequestCountProvider(teacherId));
        ref.invalidate(pendingBookingsCountProvider(teacherId));
        ref.invalidate(awaitingConfirmationProposalsProvider(teacherId));
        ref.invalidate(expiringSoonSubscriptionsProvider);
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

            // Stats Row (3 key numbers)
            _buildStatsRow(
              context,
              todayLessons,
              unpaidSummaryAsync,
              lessonStatsAsync,
            ),

            const SizedBox(height: AppSpacing.space6),

            // Urgent Actions Section
            UrgentActionsSection(
              teacherId: teacherId,
              pendingRequests: pendingRequestsAsync.valueOrNull ?? 0,
              pendingBookings: pendingBookingsAsync.valueOrNull ?? 0,
              awaitingConfirm: awaitingConfirmAsync.valueOrNull ?? [],
              expiringSoon: expiringSoonAsync.valueOrNull ?? [],
            ),

            const SizedBox(height: AppSpacing.space6),

            // Assignment Summary Section
            const AssignmentSummarySection(),

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

            const SizedBox(height: AppSpacing.space4),

            // Quick feedback button
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.quickFeedbackList),
              icon: const Icon(Icons.edit_note, size: 20),
              label: const Text('피드백 보내기'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

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
        Row(
          children: [
            _buildLessonRequestsButton(context, ref),
            _buildPendingBookingsButton(context, ref),
            IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: '알림',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
    AsyncValue<({int totalAmount, int studentCount})> unpaidSummaryAsync,
    AsyncValue<Map<String, int>> lessonStatsAsync,
  ) {
    // Today's lesson card (always shown)
    final todayCard = todayLessons.when(
      data:
          (lessons) => StatCard(
            title: '오늘 레슨',
            value: '${lessons.length}회',
            color: AppColors.primary,
            icon: Icons.today,
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

    // This month card (always shown)
    final monthCard = lessonStatsAsync.when(
      data:
          (stats) => StatCard(
            title: '이번 달',
            value: '${stats['completed'] ?? 0}회',
            subtitle: '완료',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
      loading:
          () => StatCard(
            title: '이번 달',
            value: '-',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
      error:
          (_, __) =>
              StatCard(title: '이번 달', value: '-', color: AppColors.success),
    );

    // Unpaid card (only shown when totalAmount > 0)
    return unpaidSummaryAsync.when(
      data: (summary) {
        final cards = <StatCard>[
          todayCard,
          if (summary.totalAmount > 0) ...[
            () {
              final formattedAmount =
                  summary.totalAmount >= 10000
                      ? '${(summary.totalAmount / 10000).toStringAsFixed(0)}만원'
                      : '${summary.totalAmount}원';
              return StatCard(
                title: '미수금',
                value: formattedAmount,
                subtitle: '${summary.studentCount}명',
                color: AppColors.warning,
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => context.push(AppRoutes.outstandingPayments),
              );
            }(),
          ],
          monthCard,
        ];
        return StatCardRow(cards: cards);
      },
      loading: () => StatCardRow(cards: [todayCard, monthCard]),
      error: (_, __) => StatCardRow(cards: [todayCard, monthCard]),
    );
  }

  Widget _buildTodayLessonsHeader(
    BuildContext context,
    AsyncValue<List<Lesson>> todayLessons,
  ) {
    final lessonCount = todayLessons.valueOrNull?.length ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.schedule, size: 20, color: AppColors.textSecondaryLight),
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
        if (lessonCount > 3)
          TextButton.icon(
            onPressed: onViewAllLessons,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('전체보기'),
          ),
      ],
    );
  }

  Widget _buildLessonRequestsButton(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final pendingCountAsync = ref.watch(
      pendingLessonRequestCountProvider(teacherId),
    );

    return pendingCountAsync.when(
      data: (count) {
        return Stack(
          children: [
            IconButton(
              onPressed:
                  () => context.push(
                    AppRoutes.lessonRequests,
                    extra: {'teacherId': teacherId},
                  ),
              icon: const Icon(Icons.person_add_outlined),
              tooltip: '레슨 요청',
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading:
          () => IconButton(
            onPressed:
                () => context.push(
                  AppRoutes.lessonRequests,
                  extra: {'teacherId': teacherId},
                ),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: '레슨 요청',
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPendingBookingsButton(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final pendingCountAsync = ref.watch(
      pendingBookingsCountProvider(teacherId),
    );

    return pendingCountAsync.when(
      data: (count) {
        return Stack(
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.pendingBookings),
              icon: const Icon(Icons.event_note_outlined),
              tooltip: '승인 대기',
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading:
          () => IconButton(
            onPressed: () => context.push(AppRoutes.pendingBookings),
            icon: const Icon(Icons.event_note_outlined),
            tooltip: '승인 대기',
          ),
      error: (_, __) => const SizedBox.shrink(),
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
        child: Row(
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
              onTap: () => context.push('/lessons/${lesson.id}'),
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
