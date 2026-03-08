import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../relationship/domain/entities/relationship_status.dart';
import '../../../relationship/domain/entities/teacher_student_relation.dart';
import '../../../relationship/presentation/providers/relationship_providers.dart';

/// Screen showing the student's connected teachers
class MyTeachersScreen extends ConsumerWidget {
  const MyTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(currentUserIdProvider);
    final relationsAsync = ref.watch(studentRelationshipsProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 선생님'),
      ),
      body: relationsAsync.when(
        data: (relations) => _buildContent(context, relations),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '데이터를 불러올 수 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<TeacherStudentRelation> relations) {
    if (relations.isEmpty) {
      return _buildEmptyState();
    }

    // Sort: active first, then by last lesson date
    final sorted = [...relations]..sort((a, b) {
        final aActive = a.status == RelationshipStatus.active ? 0 : 1;
        final bActive = b.status == RelationshipStatus.active ? 0 : 1;
        if (aActive != bActive) return aActive.compareTo(bActive);
        return (b.lastLessonAt ?? b.createdAt)
            .compareTo(a.lastLessonAt ?? a.createdAt);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) => _TeacherCard(relation: sorted[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '연결된 선생님이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '선생님을 검색하여 레슨을 시작해보세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final TeacherStudentRelation relation;

  const _TeacherCard({required this.relation});

  @override
  Widget build(BuildContext context) {
    final isActive = relation.status == RelationshipStatus.active;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          onTap: () => context.push(
            AppRoutes.teacherDetail.replaceFirst(':id', relation.teacherId),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Teacher avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isActive
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceSecondaryLight,
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),

                    // Teacher info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '선생님', // Mock - will be teacher name
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              _buildStatusBadge(),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            '바이올린', // Mock - will be from teacher profile
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiaryLight,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.space3),
                Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: AppSpacing.space3),

                // Stats row
                Row(
                  children: [
                    _buildStat(
                      Icons.school_outlined,
                      '총 레슨',
                      '${relation.totalLessonCount}회',
                    ),
                    const SizedBox(width: AppSpacing.space6),
                    if (relation.lastLessonAt != null)
                      _buildStat(
                        Icons.calendar_today_outlined,
                        '마지막 레슨',
                        _formatRelativeDate(relation.lastLessonAt!),
                      ),
                    const SizedBox(width: AppSpacing.space6),
                    _buildStat(
                      Icons.access_time_outlined,
                      '레슨 기간',
                      _formatDuration(relation.createdAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (label, color) = switch (relation.status) {
      RelationshipStatus.active => ('수강 중', AppColors.practiceGood),
      RelationshipStatus.expired => ('만료', AppColors.practiceNormal),
      RelationshipStatus.trialBooked => ('체험 예약', AppColors.info),
      RelationshipStatus.past => ('종료', AppColors.textTertiaryLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}개월 전';
    return '${diff.inDays ~/ 365}년 전';
  }

  String _formatDuration(DateTime startDate) {
    final months = DateTime.now().difference(startDate).inDays ~/ 30;
    if (months < 1) return '1개월 미만';
    if (months < 12) return '$months개월';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years년';
    return '$years년 $remainingMonths개월';
  }
}
