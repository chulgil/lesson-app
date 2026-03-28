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
import '../widgets/decline_bottom_sheet.dart';
import '../widgets/lesson_request_list.dart';
import '../widgets/unified_approval_bottom_sheet.dart';
import '../widgets/unified_request_card.dart';

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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
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
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('오류가 발생했습니다',
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight)),
              const SizedBox(height: AppSpacing.space4),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
        data: (requests) {
          return CustomScrollView(
            slivers: [
              // Unified lesson requests section
              _UnifiedRequestsSection(teacherId: teacherId),
              // Legacy request list
              SliverToBoxAdapter(
                child: LessonRequestList(requests: requests),
              ),
            ],
          );
        },
      ),
    );
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
      error: (e, __) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            '통합 레슨 신청을 불러올 수 없습니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
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
                onProposeAlternatives:
                    (request.status == UnifiedRequestStatus.pending ||
                            request.status ==
                                UnifiedRequestStatus.negotiating)
                        ? () => _handleDeclineOrPropose(
                            context, ref, request)
                        : null,
                onSendProposal:
                    request.status == UnifiedRequestStatus.timeConfirmed
                        ? () => _handleSendProposal(context, ref, request)
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
    // v2.0: Show approval bottom sheet with 3 preferred slots
    if (request.preferredSlots.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => UnifiedApprovalBottomSheet(
            request: request,
            scrollController: scrollController,
            onComplete: () {
              ref.invalidate(teacherUnifiedRequestsProvider(teacherId));
            },
          ),
        ),
      );
      return;
    }

    // Legacy: direct approve (no preferred slots)
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
    await _handleDeclineOrPropose(context, ref, request);
  }

  Future<void> _handleDeclineOrPropose(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    final result = await showDeclineBottomSheet(
      context,
      durationMinutes: request.preferredDuration,
      teacherId: request.teacherId,
    );
    if (result == null) return;

    try {
      final actions = UnifiedLessonRequestActions(ref);

      if (result.suggestedSlots.isEmpty) {
        // Message only → reject
        await actions.rejectRequest(
          request.id,
          request.teacherId,
          request.studentId,
          reason: result.message,
        );
      } else {
        // With alternatives → propose
        await actions.proposeAlternatives(
          request.id,
          request.teacherId,
          request.studentId,
          slots: result.suggestedSlots.map((s) => TimeSlotOption(
            id: s.id,
            dayOfWeek: s.dayOfWeek - 1, // TimeSlot is 1-based, TimeSlotOption is 0-based
            startTime: '${s.startTime.hour.toString().padLeft(2, '0')}:${s.startTime.minute.toString().padLeft(2, '0')}',
            endTime: '${s.endTime.hour.toString().padLeft(2, '0')}:${s.endTime.minute.toString().padLeft(2, '0')}',
          )).toList(),
          message: result.message,
        );
      }

      if (context.mounted) {
        ref.invalidate(teacherUnifiedRequestsProvider(teacherId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.suggestedSlots.isNotEmpty
                ? '대안 시간과 함께 안내가 전달되었습니다'
                : '레슨 신청을 거절했습니다'),
            backgroundColor: result.suggestedSlots.isNotEmpty
                ? AppColors.success
                : AppColors.textSecondaryLight,
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

  Future<void> _handleSendProposal(
    BuildContext context,
    WidgetRef ref,
    UnifiedLessonRequest request,
  ) async {
    if (request.type == LessonRequestType.trial) {
      // Trial: complete directly (체험레슨은 무료이므로 수강권 불필요)
      try {
        final actions = UnifiedLessonRequestActions(ref);
        await actions.completeRequest(
          request.id,
          request.teacherId,
          request.studentId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('체험레슨 예약이 완료되었습니다'),
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
    } else {
      // Regular: navigate to subscription issuance with pre-filled data
      if (context.mounted) {
        context.push(
          '${AppRoutes.issueSubscription}'
          '?studentId=${request.studentId}'
          '&lessonRequestId=${request.id}',
        );
      }
    }
  }
}
