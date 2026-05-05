import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/parent_home/domain/entities/parent_child_relation.dart';
import '../../../../features/students/students_facade.dart';

/// Card widget displaying a child's information for parent dashboard
class ChildCard extends ConsumerWidget {
  final ParentChildRelation relation;

  const ChildCard({super.key, required this.relation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(relation.studentId));

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children: [
              // Header row with avatar and name
              Row(
                children: [
                  // Avatar
                  // §7.132: CircleAvatar 유지 (사람 = 원형 관습). white → paper.
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.paperAccent,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0] : 'S',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),

                  // Name and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              student.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (relation.isPrimaryGuardian) ...[
                              const SizedBox(width: AppSpacing.space2),
                              // §7.132: paperAccent.alpha → paperAccentSoft.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paperAccentSoft,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  '주 보호자',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.paperAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          student.instrument.isEmpty
                              ? '악기 미설정'
                              : student.instrument,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Billing badge
                  // §7.132: paperAccent.alpha → paperAccentSoft.
                  if (relation.isBillingTarget) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payment,
                            size: 14,
                            color: AppColors.paperAccent,
                          ),
                          const SizedBox(width: AppSpacing.space1),
                          Text(
                            '청구 대상',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                  ],

                  // Chevron
                  Icon(Icons.chevron_right, color: AppColors.inkTertiary),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),
              const Divider(),
              const SizedBox(height: AppSpacing.space3),

              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.school,
                    label: AppStrings.parentHomeNextLesson,
                    value: '내일 14:00',
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  _buildStatItem(
                    icon: Icons.fitness_center,
                    label: AppStrings.parentHomeTodayPracticeLabel,
                    value: '45분',
                    color: AppColors.paperOk,
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: AppStrings.parentHomePracticeStreak,
                    value: '5일',
                    color: AppColors.paperAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading:
          () => Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.paperDark,
              borderRadius: BorderRadius.zero,
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              // §7.132: paperAccent.alpha → paperAccentSoft.
              color: AppColors.paperAccentSoft,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              '정보를 불러올 수 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }
}
