import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/lesson_request.dart';
import 'lesson_request_card.dart';

/// List widget for date-filtered lesson requests
class LessonRequestList extends StatelessWidget {
  final List<LessonRequest> requests;
  final DateTime selectedDate;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final void Function(String) onToggleSelection;

  const LessonRequestList({
    super.key,
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
    final dayRequests =
        requests
            .where(
              (r) =>
                  r.createdAt.year == selectedDate.year &&
                  r.createdAt.month == selectedDate.month &&
                  r.createdAt.day == selectedDate.day,
            )
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ...dayRequests.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: LessonRequestCard(
                request: request,
                isSelectionMode: isSelectionMode,
                isSelected: selectedIds.contains(request.id),
                onToggleSelection: () => onToggleSelection(request.id),
              ),
            ),
          ),

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
