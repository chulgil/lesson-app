import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_student_relation.dart';

/// Screen for selecting lesson type based on teacher-student relationship
class LessonTypeSelectScreen extends ConsumerWidget {
  final String teacherId;
  final String teacherName;

  const LessonTypeSelectScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get actual relation from provider when backend is ready
    // For now, use mock relation based on teacherId
    final relation = _getMockRelation(teacherId);
    final availableTypes = relation.availableLessonTypes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 신청'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher info header
              _buildTeacherHeader(),

              const SizedBox(height: AppSpacing.space6),

              // Relation status badge
              _buildRelationBadge(relation),

              const SizedBox(height: AppSpacing.space4),

              // Section title
              Text(
                '레슨 유형을 선택해주세요',
                style: AppTypography.headingMedium,
              ),

              const SizedBox(height: AppSpacing.space4),

              // Lesson type cards
              Expanded(
                child: ListView(
                  children: LessonType.values.map((type) {
                    final isAvailable = availableTypes.contains(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                      child: _LessonTypeCard(
                        type: type,
                        isAvailable: isAvailable,
                        onTap: isAvailable
                            ? () => _onLessonTypeSelected(context, type)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary,
          child: Text(
            teacherName.isNotEmpty ? teacherName[0] : '?',
            style: AppTypography.headingMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '선생님',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelationBadge(TeacherStudentRelation relation) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: relation.statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRelationIcon(relation.status),
            size: 16,
            color: relation.statusColor,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            relation.statusLabel,
            style: AppTypography.bodySmall.copyWith(
              color: relation.statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRelationIcon(RelationStatus status) {
    switch (status) {
      case RelationStatus.none:
        return Icons.person_add;
      case RelationStatus.active:
        return Icons.check_circle;
      case RelationStatus.inactive:
        return Icons.history;
    }
  }

  TeacherStudentRelation _getMockRelation(String teacherId) {
    // TODO: Replace with actual provider when backend is ready
    // For demo purposes, return different relations based on teacherId
    // In production, this will be fetched from the backend

    // Mock: Return different relations for testing
    RelationStatus status;
    DateTime? lastLessonDate;
    int totalLessonCount = 0;

    switch (teacherId) {
      case 'teacher_1':
        // First teacher: currently active regular lessons
        status = RelationStatus.active;
        lastLessonDate = DateTime.now().subtract(const Duration(days: 3));
        totalLessonCount = 12;
        break;
      case 'teacher_2':
        // Second teacher: had lessons before, now inactive
        status = RelationStatus.inactive;
        lastLessonDate = DateTime.now().subtract(const Duration(days: 60));
        totalLessonCount = 8;
        break;
      default:
        // Other teachers: first time meeting
        status = RelationStatus.none;
        break;
    }

    return TeacherStudentRelation(
      teacherId: teacherId,
      studentId: 'current_student_id',
      status: status,
      lastLessonDate: lastLessonDate,
      totalLessonCount: totalLessonCount,
    );
  }

  void _onLessonTypeSelected(BuildContext context, LessonType type) {
    switch (type) {
      case LessonType.trial:
        // Navigate to trial lesson request screen
        context.push(
          '${AppRoutes.trialLessonRequest}?teacherId=$teacherId&teacherName=${Uri.encodeComponent(teacherName)}',
        );
        break;
      case LessonType.regular:
        // TODO: Navigate to regular lesson schedule screen
        // For now, show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정기 레슨 신청 기능은 준비 중입니다'),
          ),
        );
        break;
      case LessonType.oneTime:
        // TODO: Navigate to one-time lesson request screen
        // For now, show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('1회 추가 레슨 신청 기능은 준비 중입니다'),
          ),
        );
        break;
    }
  }
}

/// Lesson type selection card
class _LessonTypeCard extends StatelessWidget {
  final LessonType type;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _LessonTypeCard({
    required this.type,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: isAvailable
              ? type.color.withValues(alpha: 0.08)
              : AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: isAvailable ? type.color : AppColors.borderLight,
            width: isAvailable ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? type.color.withValues(alpha: 0.15)
                        : AppColors.surfaceSecondaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Icon(
                    type.icon,
                    size: 24,
                    color: isAvailable ? type.color : AppColors.textTertiaryLight,
                  ),
                ),

                const SizedBox(width: AppSpacing.space4),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? AppColors.textPrimaryLight
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: isAvailable
                              ? AppColors.textSecondaryLight
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow or lock icon
                Icon(
                  isAvailable ? Icons.chevron_right : Icons.lock_outline,
                  size: 24,
                  color: isAvailable
                      ? AppColors.textSecondaryLight
                      : AppColors.textTertiaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
