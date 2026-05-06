import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
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
                AppStrings.parentHomeConnectedChildren,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed:
                    () => context.push(
                      '${AppRoutes.childProfiles}?parentId=$parentId',
                    ),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text(AppStrings.parentHomeManage),
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
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
            ),
            child: childProfilesAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (_, __) => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Text(AppStrings.errorOccurred),
                  ),
              data:
                  (profiles) => Column(
                    children: [
                      ...profiles.map(
                        (profile) => _buildChildItem(context, profile),
                      ),
                      if (profiles.isNotEmpty)
                        Divider(
                          height: 1,
                          indent: AppSpacing.space4 + 24 + AppSpacing.space3,
                          color: AppColors.inkQuaternary,
                        ),
                      ProfileMenuItemTile(
                        item: ProfileMenuItem(
                          icon: Icons.add_circle_outline,
                          label: AppStrings.parentHomeAddChild,
                          labelColor: AppColors.paperAccent,
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
            builder:
                (context) => ChildProfileFormScreen(
                  parentId: parentId,
                  existingProfile: profile,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            // §7.132: CircleAvatar 유지 (사람 = 원형 관습). white → paper.
            CircleAvatar(
              radius: 16,
              backgroundColor: profile.profileColor,
              child: Text(
                profile.initial,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.paper,
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
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        '(만 ${profile.age}세)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profile.instrumentLabel} • ${profile.teacherName ?? "선생님 미연결"}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    profile.isActive
                        ? AppColors.paperDark
                        : AppColors.paperDark,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                profile.status.label,
                style: AppTypography.caption.copyWith(
                  color:
                      profile.isActive
                          ? AppColors.paperOk
                          : AppColors.inkTertiary,
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
    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notebook × Score: 카드 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
                  Text(
                    AppStrings.parentHomeAddChildMethod,
                    style: NotebookTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    '자녀를 추가할 방법을 선택하세요',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space6),

                  // Option 1: Add child profile (under 14)
                  AddChildOption(
                    icon: Icons.child_care,
                    iconColor: AppColors.paperAccent,
                    title: '만 14세 미만 자녀 등록',
                    description: '별도 계정 없이 학부모 계정에서 관리',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                        '${AppRoutes.addChildProfile}?parentId=$parentId',
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.space3),

                  // Option 2: Connect existing student
                  AddChildOption(
                    icon: Icons.link,
                    iconColor: AppColors.paperAccent,
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
