import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/lesson_request.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/lesson_request_providers.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/lesson_request_list.dart';
import '../widgets/unified_request_card.dart';

/// State provider for selection mode
final _isSelectionModeProvider = StateProvider<bool>((ref) => false);

/// State provider for selected request IDs
final _selectedRequestIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Screen for teachers to view and respond to lesson requests.
///
/// Shows all pending requests sorted by expiration (urgent first),
/// consistent with other "즉시 확인" screens (PendingBookings, etc.).
class LessonRequestsScreen extends ConsumerWidget {
  final String teacherId;

  const LessonRequestsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(teacherLessonRequestsProvider(teacherId));
    final isSelectionMode = ref.watch(_isSelectionModeProvider);
    final selectedIds = ref.watch(_selectedRequestIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (isSelectionMode) {
              ref.read(_isSelectionModeProvider.notifier).state = false;
              ref.read(_selectedRequestIdsProvider.notifier).state = {};
            } else {
              context.pop();
            }
          },
          icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back),
        ),
        title: requestsAsync.when(
          loading: () => const Text('레슨 요청'),
          error: (_, __) => const Text('레슨 요청'),
          data: (requests) {
            final pendingCount = requests
                .where(
                  (r) =>
                      r.status == LessonRequestStatus.pending && !r.isExpired,
                )
                .length;

            if (isSelectionMode) {
              return Text('${selectedIds.length}명 선택');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('레슨 요청'),
                if (pendingCount > 0)
                  Text(
                    '대기 중 $pendingCount건',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          requestsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (requests) {
              final pendingCount = requests
                  .where(
                    (r) =>
                        r.status == LessonRequestStatus.pending && !r.isExpired,
                  )
                  .length;

              if (pendingCount == 0) return const SizedBox.shrink();

              if (isSelectionMode) {
                return TextButton(
                  onPressed: () {
                    final allPendingIds = requests
                        .where(
                          (r) =>
                              r.status == LessonRequestStatus.pending &&
                              !r.isExpired,
                        )
                        .map((r) => r.id)
                        .toSet();
                    if (selectedIds.length == pendingCount) {
                      ref.read(_selectedRequestIdsProvider.notifier).state = {};
                    } else {
                      ref.read(_selectedRequestIdsProvider.notifier).state =
                          allPendingIds;
                    }
                  },
                  child: Text(
                    selectedIds.length == pendingCount ? '전체 해제' : '전체 선택',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              return TextButton(
                onPressed: () {
                  ref.read(_isSelectionModeProvider.notifier).state = true;
                },
                child: Text(
                  '선택',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
        data: (requests) {
          final pendingRequests = requests
              .where(
                (r) =>
                    r.status == LessonRequestStatus.pending && !r.isExpired,
              )
              .toList();
          final selectedRequests =
              pendingRequests.where((r) => selectedIds.contains(r.id)).toList();

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Unified lesson requests section (Phase 1)
                    _UnifiedRequestsSection(teacherId: teacherId),
                    // Legacy request list
                    SliverToBoxAdapter(
                      child: LessonRequestList(
                        requests: requests,
                        isSelectionMode: isSelectionMode,
                        selectedIds: selectedIds,
                        onToggleSelection: (requestId) {
                          final current = ref
                              .read(_selectedRequestIdsProvider.notifier)
                              .state;
                          if (current.contains(requestId)) {
                            ref
                                .read(_selectedRequestIdsProvider.notifier)
                                .state = {
                              ...current,
                            }..remove(requestId);
                          } else {
                            ref
                                .read(_selectedRequestIdsProvider.notifier)
                                .state = {
                              ...current,
                              requestId,
                            };
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom action bar (when items selected)
              if (isSelectionMode && selectedIds.isNotEmpty)
                _buildBottomActionBar(context, ref, selectedRequests),
            ],
          );
        },
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
    final studentIds = requests.map((r) => r.studentId).toList();
    final requestIds = requests.map((r) => r.id).toList();

    context.push(
      '${AppRoutes.issueSubscription}?studentIds=${studentIds.join(',')}&lessonRequestIds=${requestIds.join(',')}',
    );

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

        for (final request in requests) {
          await ref
              .read(lessonRequestActionsProvider.notifier)
              .declineRequest(requestId: request.id, reason: reason);
        }

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
              content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}

/// Section showing unified lesson requests with approve/reject actions.
class _UnifiedRequestsSection extends ConsumerWidget {
  final String teacherId;

  const _UnifiedRequestsSection({required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unifiedAsync = ref.watch(teacherUnifiedRequestsProvider(teacherId));

    return unifiedAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (requests) {
        if (requests.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.space4,
                    AppSpacing.screenPadding,
                    AppSpacing.space2,
                  ),
                  child: Text(
                    '레슨 신청',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final request = requests[index - 1];
              return UnifiedRequestCard(
                request: request,
                onApprove: request.status == UnifiedRequestStatus.pending
                    ? () => _handleApprove(context, ref, request)
                    : null,
                onReject: request.status == UnifiedRequestStatus.pending
                    ? () => _handleReject(context, ref, request)
                    : null,
              );
            },
            childCount: requests.length + 1, // +1 for header
          ),
        );
      },
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.approveRequest(
        request.id,
        request.teacherId,
        request.studentId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('레슨 신청을 승인했습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final reasonController = TextEditingController(
      text: '스케줄이 꽉 차서 다음에 신청해주세요',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 신청 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('거절 사유를 입력해주세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '거절 사유 (선택)',
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
              backgroundColor: AppColors.error,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final actions = UnifiedLessonRequestActions(ref);
        await actions.rejectRequest(
          request.id,
          request.teacherId,
          request.studentId,
          reason: reasonController.text,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('레슨 신청을 거절했습니다'),
              backgroundColor: AppColors.textSecondaryLight,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오류가 발생했습니다'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
    reasonController.dispose();
  }
}
