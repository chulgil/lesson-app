import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/lesson_request.dart';
import 'lesson_request_card.dart';

/// List widget for lesson requests grouped by status.
///
/// Shows pending requests sorted by expiration (urgent first),
/// followed by past requests (most recent first).
class LessonRequestList extends StatelessWidget {
  final List<LessonRequest> requests;

  const LessonRequestList({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context) {
    // Split into pending vs past
    final pendingRequests = requests
        .where((r) => r.status == LessonRequestStatus.pending && !r.isExpired)
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt)); // Urgent first

    final pastRequests = requests
        .where((r) =>
            r.status != LessonRequestStatus.pending || r.isExpired)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Recent first

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      children: [
        // Pending requests
        if (pendingRequests.isNotEmpty) ...[
          ...pendingRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: LessonRequestCard(request: request),
            ),
          ),
        ],

        // Empty pending state (only when there are past requests)
        if (pendingRequests.isEmpty && pastRequests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: Text(
                '대기 중인 요청이 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ),
          ),

        // Past requests section
        if (pastRequests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          _buildSectionHeader('지난 요청', pastRequests.length),
          const SizedBox(height: AppSpacing.space3),
          ...pastRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: LessonRequestCard(request: request),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: AppColors.textSecondaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: AppSpacing.space1),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.space1),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            '대기 중인 레슨 요청이 없습니다',
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
    );
  }
}
