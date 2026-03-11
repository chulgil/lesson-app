import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../schedule/domain/entities/lesson_request.dart';
import '../../../../schedule/presentation/providers/lesson_request_providers.dart';

/// Banner showing active lesson requests status for a student.
class LessonRequestsBanner extends ConsumerWidget {
  final String studentId;

  const LessonRequestsBanner({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(studentLessonRequestsProvider(studentId));

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        final activeRequests =
            requests
                .where(
                  (r) =>
                      (r.status == LessonRequestStatus.pending &&
                          !r.isExpired) ||
                      r.status == LessonRequestStatus.proposalSent,
                )
                .toList();

        if (activeRequests.isEmpty) {
          return const SizedBox.shrink();
        }

        final proposalCount =
            activeRequests
                .where((r) => r.status == LessonRequestStatus.proposalSent)
                .length;
        final pendingCount =
            activeRequests
                .where(
                  (r) =>
                      r.status == LessonRequestStatus.pending && !r.isExpired,
                )
                .length;

        Color bannerColor;
        IconData bannerIcon;
        String title;
        String subtitle;

        if (proposalCount > 0) {
          bannerColor = AppColors.success;
          bannerIcon = Icons.card_giftcard;
          title = '수강권 제안 도착!';
          subtitle =
              proposalCount == 1
                  ? '선생님이 수강권을 제안했습니다'
                  : '$proposalCount건의 수강권 제안이 있습니다';
        } else {
          bannerColor = AppColors.info;
          bannerIcon = Icons.hourglass_empty;
          title = '레슨 요청 대기 중';
          subtitle =
              pendingCount == 1
                  ? '선생님 응답을 기다리고 있습니다'
                  : '$pendingCount건의 요청이 대기 중입니다';
        }

        return GestureDetector(
          onTap: () {
            context.push('${AppRoutes.myLessonRequests}?studentId=$studentId');
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bannerColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(bannerIcon, color: bannerColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
