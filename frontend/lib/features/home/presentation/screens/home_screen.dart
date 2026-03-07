import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/debug_role_switcher.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../models/lesson.dart';
import '../../../../providers/providers.dart';
import '../../../schedule/presentation/providers/lesson_request_providers.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/domain/entities/subscription_proposal.dart';
import '../../../subscription/presentation/providers/subscription_proposal_providers.dart';
import '../../../subscription/presentation/widgets/subscription_badge.dart';
import '../../../schedule/presentation/screens/schedule_tab.dart';
import '../../../profile/presentation/screens/profile_tab.dart';
import '../../../students/presentation/screens/students_tab.dart';
import '../widgets/assignment_summary_section.dart';

/// Home screen (Teacher Dashboard)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DebugWrapper(
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _DashboardTab(
                onViewAllLessons: () => setState(() => _currentIndex = 1),
              ),
              const ScheduleTab(),
              const StudentsTab(),
              const ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '스케줄',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: '학생',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

/// Dashboard Tab - 핵심 숫자 + 즉시 확인 필요 + 오늘의 레슨
class _DashboardTab extends ConsumerWidget {
  final VoidCallback onViewAllLessons;

  const _DashboardTab({required this.onViewAllLessons});

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

            // Stats Row (핵심 숫자 3개)
            _buildStatsRow(
              context,
              todayLessons,
              unpaidSummaryAsync,
              lessonStatsAsync,
            ),

            const SizedBox(height: AppSpacing.space6),

            // Urgent Actions Section (즉시 확인 필요)
            _buildUrgentActionsSection(
              context,
              ref,
              pendingRequestsAsync,
              pendingBookingsAsync,
              awaitingConfirmAsync,
              expiringSoonAsync,
            ),

            const SizedBox(height: AppSpacing.space6),

            // Assignment Summary Section (이번 주 과제)
            const AssignmentSummarySection(),

            const SizedBox(height: AppSpacing.space6),

            // Today's Lessons Section (오늘의 레슨)
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

  Widget _buildUrgentActionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> pendingRequestsAsync,
    AsyncValue<int> pendingBookingsAsync,
    AsyncValue<List<SubscriptionProposal>> awaitingConfirmAsync,
    AsyncValue<List<Subscription>> expiringSoonAsync,
  ) {
    final pendingRequests = pendingRequestsAsync.valueOrNull ?? 0;
    final pendingBookings = pendingBookingsAsync.valueOrNull ?? 0;
    final awaitingConfirmCount = awaitingConfirmAsync.valueOrNull?.length ?? 0;
    final expiringSoonList = expiringSoonAsync.valueOrNull ?? [];
    final expiringSoonStudentCount =
        expiringSoonList.map((s) => s.studentId).toSet().length;
    final teacherId = ref.watch(currentUserIdProvider);

    final totalUrgent = pendingRequests +
        pendingBookings +
        (awaitingConfirmCount > 0 ? 1 : 0) +
        (expiringSoonStudentCount > 0 ? 1 : 0);

    if (totalUrgent == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '즉시 확인 필요',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalUrgent',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              if (pendingRequests > 0)
                _buildUrgentItem(
                  context,
                  icon: Icons.person_add,
                  iconColor: AppColors.error,
                  title: '레슨 요청 $pendingRequests건 대기',
                  onTap:
                      () => context.push(
                        AppRoutes.lessonRequests,
                        extra: {'teacherId': teacherId},
                      ),
                ),
              if (pendingBookings > 0)
                _buildUrgentItem(
                  context,
                  icon: Icons.event_note,
                  iconColor: AppColors.warning,
                  title: '예약 승인 $pendingBookings건 대기',
                  onTap: () => context.push(AppRoutes.pendingBookings),
                  showDivider: pendingRequests > 0,
                ),
              if (awaitingConfirmCount > 0)
                _buildUrgentItem(
                  context,
                  icon: Icons.payments,
                  iconColor: AppColors.warning,
                  title: '입금 확인 $awaitingConfirmCount건 대기',
                  onTap:
                      () => context.push(
                        '${AppRoutes.proposalConfirm}?teacherId=$teacherId',
                      ),
                  showDivider: pendingRequests > 0 || pendingBookings > 0,
                ),
              if (expiringSoonStudentCount > 0)
                _buildUrgentItem(
                  context,
                  icon: Icons.card_membership,
                  iconColor: AppColors.warning,
                  title: '수강권 임박 $expiringSoonStudentCount명',
                  onTap: () => context.push(AppRoutes.subscriptions),
                  showDivider: pendingRequests > 0 ||
                      pendingBookings > 0 ||
                      awaitingConfirmCount > 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, color: AppColors.warning.withValues(alpha: 0.2)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '확인하기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
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
            child: _LessonCard(
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

// ---- Widgets ----

class _LessonCard extends ConsumerWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const _LessonCard({required this.lesson, required this.onTap});

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
        onTap: onTap,
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

              // Info section (flexible)
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
