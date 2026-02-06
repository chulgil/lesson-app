import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../student_home/presentation/widgets/week_calendar_widget.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';

/// State provider for selected date in lesson requests
final _selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// State provider for selection mode
final _isSelectionModeProvider = StateProvider<bool>((ref) => false);

/// State provider for selected request IDs
final _selectedRequestIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Screen for teachers to view and respond to lesson requests.
///
/// Shows pending requests from previous students wanting to resume lessons.
class LessonRequestsScreen extends ConsumerWidget {
  final String teacherId;

  const LessonRequestsScreen({
    super.key,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teacherLessonRequestsProvider(teacherId));
    final selectedDate = ref.watch(_selectedDateProvider);
    final isSelectionMode = ref.watch(_isSelectionModeProvider);
    final selectedIds = ref.watch(_selectedRequestIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('오류가 발생했습니다: $e'),
          ),
          data: (requests) {
            // Get pending requests
            final pendingRequests = requests
                .where((r) =>
                    r.status == LessonRequestStatus.pending && !r.isExpired)
                .toList();
            final pendingCount = pendingRequests.length;

            // Get dates with requests
            final markedDates = requests
                .map((r) => DateTime(
                    r.createdAt.year, r.createdAt.month, r.createdAt.day))
                .toSet();

            // Get selected pending requests
            final selectedRequests = pendingRequests
                .where((r) => selectedIds.contains(r.id))
                .toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space2,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () {
                          if (isSelectionMode) {
                            // Exit selection mode
                            ref.read(_isSelectionModeProvider.notifier).state =
                                false;
                            ref.read(_selectedRequestIdsProvider.notifier).state =
                                {};
                          } else {
                            context.pop();
                          }
                        },
                        icon: Icon(
                            isSelectionMode ? Icons.close : Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSelectionMode
                                  ? '${selectedIds.length}명 선택'
                                  : '레슨 요청',
                              style: AppTypography.headingLarge,
                            ),
                            if (!isSelectionMode && pendingCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '대기 중 ${pendingCount}건',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Selection mode toggle / Select all
                      if (pendingCount > 0) ...[
                        if (isSelectionMode) ...[
                          // Select all button
                          TextButton(
                            onPressed: () {
                              final allPendingIds =
                                  pendingRequests.map((r) => r.id).toSet();
                              if (selectedIds.length == pendingCount) {
                                // Deselect all
                                ref
                                    .read(_selectedRequestIdsProvider.notifier)
                                    .state = {};
                              } else {
                                // Select all
                                ref
                                    .read(_selectedRequestIdsProvider.notifier)
                                    .state = allPendingIds;
                              }
                            },
                            child: Text(
                              selectedIds.length == pendingCount
                                  ? '전체 해제'
                                  : '전체 선택',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Enter selection mode button
                          TextButton(
                            onPressed: () {
                              ref.read(_isSelectionModeProvider.notifier).state =
                                  true;
                            },
                            child: Text(
                              '선택',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // Week Calendar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space3,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: WeekCalendarWidget(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      ref.read(_selectedDateProvider.notifier).state = date;
                    },
                    practicedDates: markedDates,
                  ),
                ),

                const SizedBox(height: AppSpacing.space3),

                // Request list
                Expanded(
                  child: _LessonRequestList(
                    requests: requests,
                    selectedDate: selectedDate,
                    isSelectionMode: isSelectionMode,
                    selectedIds: selectedIds,
                    onToggleSelection: (requestId) {
                      final current =
                          ref.read(_selectedRequestIdsProvider.notifier).state;
                      if (current.contains(requestId)) {
                        ref.read(_selectedRequestIdsProvider.notifier).state =
                            {...current}..remove(requestId);
                      } else {
                        ref.read(_selectedRequestIdsProvider.notifier).state =
                            {...current, requestId};
                      }
                    },
                  ),
                ),

                // Bottom action bar (when items selected)
                if (isSelectionMode && selectedIds.isNotEmpty)
                  _buildBottomActionBar(context, ref, selectedRequests),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    List<LessonRequest> selectedRequests,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Decline all button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showBatchDeclineDialog(context, ref, selectedRequests),
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text('모두 다음에'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  side: BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Propose to all button
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () =>
                    _navigateToBatchProposal(context, ref, selectedRequests),
                icon: const Icon(Icons.card_giftcard, size: 16),
                label: Text('${selectedRequests.length}명에게 수강권 제안'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBatchProposal(
    BuildContext context,
    WidgetRef ref,
    List<LessonRequest> requests,
  ) {
    // Get student IDs
    final studentIds = requests.map((r) => r.studentId).toList();

    // Navigate with multiple student IDs
    context.push(
      '${AppRoutes.issueSubscription}?studentIds=${studentIds.join(',')}',
    );

    // Exit selection mode
    ref.read(_isSelectionModeProvider.notifier).state = false;
    ref.read(_selectedRequestIdsProvider.notifier).state = {};
  }

  Future<void> _showBatchDeclineDialog(
    BuildContext context,
    WidgetRef ref,
    List<LessonRequest> requests,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${requests.length}명 레슨 요청 보류'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택한 ${requests.length}명의 학생에게 동일한 안내 메시지를 전달합니다.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '예: 현재 스케줄이 꽉 차서 다음 기회에 연락드릴게요.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textSecondaryLight,
            ),
            child: const Text('모두 보류'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reason = reasonController.text.isEmpty
            ? '현재 스케줄 조정이 어려워요. 다음에 꼭 연락드릴게요!'
            : reasonController.text;

        // Decline all selected requests
        for (final request in requests) {
          await ref.read(lessonRequestActionsProvider.notifier).declineRequest(
                requestId: request.id,
                reason: reason,
              );
        }

        // Exit selection mode
        ref.read(_isSelectionModeProvider.notifier).state = false;
        ref.read(_selectedRequestIdsProvider.notifier).state = {};

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${requests.length}명에게 안내 메시지를 전달했습니다'),
              backgroundColor: AppColors.textSecondaryLight,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

class _LessonRequestList extends StatelessWidget {
  final List<LessonRequest> requests;
  final DateTime selectedDate;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelection;

  const _LessonRequestList({
    required this.requests,
    required this.selectedDate,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko');

    // Filter requests for selected date
    final dayRequests = requests
        .where((r) =>
            r.createdAt.year == selectedDate.year &&
            r.createdAt.month == selectedDate.month &&
            r.createdAt.day == selectedDate.day)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final isToday = _isToday(selectedDate);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
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
              '${dayRequests.length}건',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Requests for selected date
        if (dayRequests.isNotEmpty)
          ...dayRequests.map((request) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _LessonRequestCard(
                  request: request,
                  isSelectionMode: isSelectionMode,
                  isSelected: selectedIds.contains(request.id),
                  onToggleSelection: () => onToggleSelection(request.id),
                ),
              )),

        // Empty state
        if (dayRequests.isEmpty) _buildEmptyState(context),

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '이 날짜에 레슨 요청이 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '이전 학생이 레슨을 요청하면\n여기에 표시됩니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lesson request card - styled like TrialBookingCard
class _LessonRequestCard extends ConsumerWidget {
  final LessonRequest request;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _LessonRequestCard({
    required this.request,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending =
        request.status == LessonRequestStatus.pending && !request.isExpired;

    return GestureDetector(
      onTap: isSelectionMode && isPending ? onToggleSelection : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isPending
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info & status
            Row(
              children: [
                // Checkbox in selection mode
                if (isSelectionMode && isPending) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                ],

                // Student avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _getStudentInitial(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Student name & time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '레슨요청',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '학생 ${request.studentId.replaceAll('student_', '#')}',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Previous schedule info
            if (request.hasPreviousSchedule) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이전 스케줄',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            LessonDateUtils.formatScheduleDisplay(
                              weekday: request.previousLessonDay!,
                              time: request.previousLessonTime!,
                              includeWeekly: true,
                            ),
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (request.keepPreviousSchedule)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '유지 희망',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Message
            if (request.message != null && request.message!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '메시지',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${request.message}"',
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            // Timing & expiration info
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '희망 시작: ${request.preferredTiming.label}',
                    style: AppTypography.bodyMedium,
                  ),
                  if (isPending) ...[
                    const Spacer(),
                    Text(
                      request.formattedExpiration,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Decline reason (shown as guidance message)
            if (request.status == LessonRequestStatus.declined &&
                request.declineReason != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안내 메시지',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.declineReason!,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (for pending requests, not in selection mode)
            if (isPending && !isSelectionMode) ...[
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeclineDialog(context, ref),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('다음에'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryLight,
                        side: BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(
                          '${AppRoutes.issueSubscription}?studentId=${request.studentId}',
                        );
                      },
                      icon: const Icon(Icons.card_giftcard, size: 16),
                      label: const Text('수강권 제안'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStudentInitial() {
    // Extract number from studentId like "student_1" -> "1"
    final number = request.studentId.replaceAll(RegExp(r'[^0-9]'), '');
    return number.isNotEmpty ? number : 'S';
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;
    String label;

    switch (request.status) {
      case LessonRequestStatus.pending:
        if (request.isExpired) {
          color = AppColors.textSecondaryLight;
          icon = Icons.schedule;
          label = '만료됨';
        } else {
          color = AppColors.warning;
          icon = Icons.hourglass_empty;
          label = '대기 중';
        }
        break;
      case LessonRequestStatus.proposalSent:
        color = AppColors.info;
        icon = Icons.send;
        label = '제안 완료';
        break;
      case LessonRequestStatus.accepted:
        color = AppColors.success;
        icon = Icons.check_circle;
        label = '수락됨';
        break;
      case LessonRequestStatus.declined:
        color = AppColors.error;
        icon = Icons.cancel;
        label = '거절됨';
        break;
      case LessonRequestStatus.expired:
        color = AppColors.textSecondaryLight;
        icon = Icons.schedule;
        label = '만료됨';
        break;
      case LessonRequestStatus.cancelled:
        color = AppColors.textSecondaryLight;
        icon = Icons.cancel;
        label = '취소됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeclineDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 요청 보류'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('학생에게 전달할 안내 메시지를 입력해주세요. (선택)'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '예: 현재 스케줄이 꽉 차서 다음 기회에 연락드릴게요.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.textSecondaryLight,
            ),
            child: const Text('보류'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(lessonRequestActionsProvider.notifier).declineRequest(
              requestId: request.id,
              reason: reasonController.text.isEmpty
                  ? '현재 스케줄 조정이 어려워요. 다음에 꼭 연락드릴게요!'
                  : reasonController.text,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('학생에게 안내 메시지를 전달했습니다'),
              backgroundColor: AppColors.textSecondaryLight,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
