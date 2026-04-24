import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Parent assignments tab for viewing child's assignments
class ParentAssignmentsTab extends ConsumerWidget {
  const ParentAssignmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과제 현황'),
        centerTitle: true,
        actions: [
          // Filter button
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Progress summary
          _buildProgressSummary(),

          const SizedBox(height: AppSpacing.space6),

          // Incomplete assignments
          _SectionHeader(
            title: '미완료 과제',
            count: 2,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space3),

          _AssignmentCard(
            title: '스케일 연습',
            description: 'G Major 3옥타브 스케일, 메트로놈 80 bpm으로 연습',
            dueDate: '내일',
            priority: AssignmentPriority.must,
            isCompleted: false,
          ),

          const SizedBox(height: AppSpacing.space3),

          _AssignmentCard(
            title: '모차르트 소나타 1악장',
            description: '전체 통주 + 카덴차 외우기',
            dueDate: '2일 남음',
            priority: AssignmentPriority.must,
            isCompleted: false,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Completed assignments
          _SectionHeader(title: '완료된 과제', count: 5, color: AppColors.paperOk),
          const SizedBox(height: AppSpacing.space3),

          _AssignmentCard(
            title: '비브라토 연습',
            description: '손목 비브라토 연습, 느린 속도로',
            dueDate: '완료됨',
            priority: AssignmentPriority.should,
            isCompleted: true,
          ),

          const SizedBox(height: AppSpacing.space3),

          _AssignmentCard(
            title: '활 긋기 연습',
            description: '전궁 연습 10분',
            dueDate: '완료됨',
            priority: AssignmentPriority.could,
            isCompleted: true,
          ),

          const SizedBox(height: AppSpacing.space3),

          _AssignmentCard(
            title: '포지션 이동 연습',
            description: '1-3 포지션 이동 연습곡',
            dueDate: '완료됨',
            priority: AssignmentPriority.should,
            isCompleted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.paperAccent, AppColors.paperAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notebook × Score: accent 배너 섹션 제목은 Playfair sectionTitle
              // 로 통일. white copyWith 유지 (§7.17).
              Text(
                '이번 주 과제',
                style: NotebookTypography.sectionTitle.copyWith(
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  '71% 완료',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: 0.71,
              backgroundColor: AppColors.paper.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressStat(label: '전체', value: '7', color: Colors.white),
              _ProgressStat(
                label: '완료',
                value: '5',
                color: AppColors.paperDark,
              ),
              _ProgressStat(
                label: '진행중',
                value: '2',
                color: AppColors.paperAccentSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Notebook × Score: 학부모 과제 탭 섹션 헤더도 Playfair sectionTitle 로 통일.
        Text(title, style: NotebookTypography.sectionTitle),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            '$count개',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headingMedium.copyWith(color: color)),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.paper.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

enum AssignmentPriority { must, should, could }

class _AssignmentCard extends StatelessWidget {
  final String title;
  final String description;
  final String dueDate;
  final AssignmentPriority priority;
  final bool isCompleted;

  const _AssignmentCard({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.inkQuaternary
                  : _getPriorityColor().withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.paperOk : AppColors.paperDark,
                  shape: BoxShape.circle,
                  border:
                      isCompleted
                          ? null
                          : Border.all(color: AppColors.inkQuaternary),
                ),
                child:
                    isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: AppSpacing.space3),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? AppColors.inkTertiary : AppColors.ink,
                  ),
                ),
              ),
              // Priority badge
              if (!isCompleted) _buildPriorityBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.schedule,
                      size: 14,
                      color:
                          isCompleted
                              ? AppColors.paperOk
                              : AppColors.inkTertiary,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      dueDate,
                      style: AppTypography.caption.copyWith(
                        color:
                            isCompleted
                                ? AppColors.paperOk
                                : dueDate.contains('내일')
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case AssignmentPriority.must:
        return AppColors.paperAccent;
      case AssignmentPriority.should:
        return AppColors.paperAccent;
      case AssignmentPriority.could:
        return AppColors.ink;
    }
  }

  String _getPriorityLabel() {
    switch (priority) {
      case AssignmentPriority.must:
        return '필수';
      case AssignmentPriority.should:
        return '권장';
      case AssignmentPriority.could:
        return '선택';
    }
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        _getPriorityLabel(),
        style: AppTypography.captionSmall.copyWith(
          color: _getPriorityColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
