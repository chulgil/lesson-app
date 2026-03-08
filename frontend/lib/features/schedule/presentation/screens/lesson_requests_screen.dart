import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../student_home/presentation/widgets/week_calendar_widget.dart';
import '../../domain/entities/lesson_request.dart';
import '../providers/lesson_request_providers.dart';
import '../widgets/lesson_request_list.dart';

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

  const LessonRequestsScreen({super.key, required this.teacherId});

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
          error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
          data: (requests) {
            // Get pending requests
            final pendingRequests =
                requests
                    .where(
                      (r) =>
                          r.status == LessonRequestStatus.pending &&
                          !r.isExpired,
                    )
                    .toList();
            final pendingCount = pendingRequests.length;

            // Get dates with requests
            final markedDates =
                requests
                    .map(
                      (r) => DateTime(
                        r.createdAt.year,
                        r.createdAt.month,
                        r.createdAt.day,
                      ),
                    )
                    .toSet();

            // Get selected pending requests
            final selectedRequests =
                pendingRequests
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
                            ref
                                .read(_selectedRequestIdsProvider.notifier)
                                .state = {};
                          } else {
                            context.pop();
                          }
                        },
                        icon: Icon(
                          isSelectionMode ? Icons.close : Icons.arrow_back,
                        ),
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
                              ref
                                  .read(_isSelectionModeProvider.notifier)
                                  .state = true;
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
                  child: LessonRequestList(
                    requests: requests,
                    selectedDate: selectedDate,
                    isSelectionMode: isSelectionMode,
                    selectedIds: selectedIds,
                    onToggleSelection: (requestId) {
                      final current =
                          ref.read(_selectedRequestIdsProvider.notifier).state;
                      if (current.contains(requestId)) {
                        ref.read(_selectedRequestIdsProvider.notifier).state = {
                          ...current,
                        }..remove(requestId);
                      } else {
                        ref.read(_selectedRequestIdsProvider.notifier).state = {
                          ...current,
                          requestId,
                        };
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
        border: Border(top: BorderSide(color: AppColors.borderLight)),
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
                onPressed:
                    () =>
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
                onPressed:
                    () => _navigateToBatchProposal(
                      context,
                      ref,
                      selectedRequests,
                    ),
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
    // Get student IDs and lesson request IDs
    final studentIds = requests.map((r) => r.studentId).toList();
    final requestIds = requests.map((r) => r.id).toList();

    // Navigate with multiple student IDs and request IDs
    context.push(
      '${AppRoutes.issueSubscription}?studentIds=${studentIds.join(',')}&lessonRequestIds=${requestIds.join(',')}',
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
      builder:
          (context) => AlertDialog(
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
        final reason =
            reasonController.text.isEmpty
                ? '현재 스케줄 조정이 어려워요. 다음에 꼭 연락드릴게요!'
                : reasonController.text;

        // Decline all selected requests
        for (final request in requests) {
          await ref
              .read(lessonRequestActionsProvider.notifier)
              .declineRequest(requestId: request.id, reason: reason);
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
