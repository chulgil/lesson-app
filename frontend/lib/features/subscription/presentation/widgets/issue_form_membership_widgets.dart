import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';

/// Radio list for selecting a membership (lesson class)
class MembershipSelectorWidget extends ConsumerWidget {
  final List<ClassMembership> memberships;
  final String? selectedMembershipId;
  final ValueChanged<String?> onChanged;

  const MembershipSelectorWidget({
    super.key,
    required this.memberships,
    required this.selectedMembershipId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RadioGroup<String>(
      groupValue: selectedMembershipId,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('레슨 선택', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.space3),
          ...memberships.map((membership) {
            final isSelected = selectedMembershipId == membership.id;
            final lessonClassAsync = ref.watch(
              lessonClassProvider(membership.lessonClassId),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: GestureDetector(
                onTap: () => onChanged(membership.id),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.paper,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.inkQuaternary,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(value: membership.id),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            lessonClassAsync.when(
                              data:
                                  (lessonClass) => Text(
                                    lessonClass?.name ?? '개인레슨',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              loading: () => const Text('...'),
                              error: (_, __) => const Text('레슨'),
                            ),
                            Text(
                              membership.instrument,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Display card for the selected membership info
class MembershipInfoCard extends ConsumerWidget {
  final List<ClassMembership> memberships;
  final String? selectedMembershipId;

  const MembershipInfoCard({
    super.key,
    required this.memberships,
    required this.selectedMembershipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = memberships.firstWhere(
      (m) => m.id == selectedMembershipId,
      orElse: () => memberships.first,
    );
    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          lessonClassAsync.when(
            data: (lessonClass) {
              final isAcademy =
                  lessonClass?.type.toString().contains('academy') ?? false;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    isAcademy ? '🏫' : '👤',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
            loading:
                () => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
            error:
                (_, __) => Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                  child: const Icon(Icons.person),
                ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                lessonClassAsync.when(
                  data:
                      (lessonClass) => Text(
                        lessonClass?.name ?? '개인레슨',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  loading: () => const Text('...'),
                  error: (_, __) => const Text('개인레슨'),
                ),
                Text(
                  '${membership.instrument} · ${membership.level ?? '레벨 미설정'}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no memberships exist
class NoMembershipState extends StatelessWidget {
  const NoMembershipState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '등록된 레슨이 없습니다',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '학생을 레슨에 먼저 등록해주세요.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state display
class SubscriptionErrorState extends StatelessWidget {
  final String error;

  const SubscriptionErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space3),
            Text('오류가 발생했습니다', style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.space2),
            Text(
              error,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
