import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/child_profile.dart';
import '../screens/child_profile_form_screen.dart';
import 'add_child_option.dart';
import 'profile_menu_section.dart';

/// Children section in the parent profile tab
class ProfileChildrenSection extends ConsumerWidget {
  final AsyncValue<List<ChildProfile>> childProfilesAsync;
  final String parentId;

  const ProfileChildrenSection({
    super.key,
    required this.childProfilesAsync,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '연결된 자녀',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.childProfiles}?parentId=$parentId'),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('관리'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: childProfilesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: Text('오류가 발생했습니다.'),
              ),
              data: (profiles) => Column(
                children: [
                  ...profiles
                      .map((profile) => _buildChildItem(context, profile)),
                  if (profiles.isNotEmpty)
                    Divider(
                      height: 1,
                      indent: AppSpacing.space4 + 24 + AppSpacing.space3,
                      color: AppColors.borderLight,
                    ),
                  ProfileMenuItemTile(
                    item: ProfileMenuItem(
                      icon: Icons.add_circle_outline,
                      label: '자녀 추가하기',
                      labelColor: AppColors.primary,
                      onTap: () => _showAddChildDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(BuildContext context, ChildProfile profile) {
    return InkWell(
      onTap: () {
        // Navigate to child profile edit
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildProfileFormScreen(
              parentId: parentId,
              existingProfile: profile,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: profile.profileColor,
              child: Text(
                profile.initial,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(profile.name, style: AppTypography.bodyLarge),
                      const SizedBox(width: 4),
                      Text(
                        '(만 ${profile.age}세)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profile.instrumentLabel} • ${profile.teacherName ?? "선생님 미연결"}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: profile.isActive
                    ? AppColors.successLight
                    : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                profile.status.label,
                style: AppTypography.caption.copyWith(
                  color: profile.isActive
                      ? AppColors.success
                      : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('자녀 추가 방법', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '자녀를 추가할 방법을 선택하세요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Option 1: Add child profile (under 14)
              AddChildOption(
                icon: Icons.child_care,
                iconColor: AppColors.primary,
                title: '만 14세 미만 자녀 등록',
                description: '별도 계정 없이 학부모 계정에서 관리',
                onTap: () {
                  Navigator.pop(context);
                  context.push('${AppRoutes.addChildProfile}?parentId=$parentId');
                },
              ),

              const SizedBox(height: AppSpacing.space3),

              // Option 2: Connect existing student
              AddChildOption(
                icon: Icons.link,
                iconColor: AppColors.secondary,
                title: '기존 학생 연결',
                description: '초대 코드로 만 14세 이상 학생 계정 연결',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.parentInviteCode);
                },
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
