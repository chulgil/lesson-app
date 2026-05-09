import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
import '../providers/child_profile_provider.dart';
import 'child_profile_form_screen.dart';

/// Screen for managing child profiles (under-14 students)
class ChildProfilesScreen extends ConsumerWidget {
  final String parentId;

  const ChildProfilesScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider(parentId));

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.parentHomeChildManagement,
        actions: const [DetailAppBarAction.add],
        onAction: (_) => _navigateToAddChild(context),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    AppStrings.errorOccurred,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    onPressed:
                        () => ref.invalidate(childProfilesProvider(parentId)),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildProfileList(context, ref, profiles);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 80,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            // Notebook × Score: 빈 상태 헤드라인 (§7.89 3축) — Playfair sectionTitle.
            Text(
              AppStrings.parentHomeNoChildren,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '만 14세 미만 자녀를 추가하여\n레슨 일정과 연습 현황을 관리해보세요',
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

  Widget _buildProfileList(
    BuildContext context,
    WidgetRef ref,
    List<ChildProfile> profiles,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        return _ChildProfileCard(
          profile: profiles[index],
          onTap: () => _navigateToEditChild(context, profiles[index]),
          onSwitchToChild:
              () => _switchToChildView(context, ref, profiles[index]),
        );
      },
    );
  }

  void _navigateToAddChild(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildProfileFormScreen(parentId: parentId),
      ),
    );
  }

  void _navigateToEditChild(BuildContext context, ChildProfile profile) {
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
  }

  void _switchToChildView(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
  ) {
    // Set selected child profile
    ref.read(selectedChildProfileProvider.notifier).select(profile);

    // Navigate to student home with child profile context
    // For now, show a message - full implementation would switch UI mode
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${profile.name}의 화면으로 전환합니다")));

    // TODO: Implement proper view switching
    // This would typically navigate to StudentHomeScreen with the child profile
  }
}

class _ChildProfileCard extends StatelessWidget {
  final ChildProfile profile;
  final VoidCallback onTap;
  final VoidCallback onSwitchToChild;

  const _ChildProfileCard({
    required this.profile,
    required this.onTap,
    required this.onSwitchToChild,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // §7.132 W1.5: CircleAvatar 유지(사람 = 원형 관습). white → paper.
              CircleAvatar(
                radius: 28,
                backgroundColor: profile.profileColor,
                child: Text(
                  profile.initial,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccentSoft.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '만 ${profile.age}세',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Row(
                      children: [
                        Icon(
                          profile.instrumentIcon,
                          size: 14,
                          color: AppColors.inkSecondary,
                        ),
                        const SizedBox(width: AppSpacing.space1),
                        Text(
                          '${profile.instrumentLabel} • ${profile.levelLabel}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (profile.teacherName != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.inkTertiary,
                          ),
                          const SizedBox(width: AppSpacing.space1),
                          Text(
                            profile.teacherName!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  // Switch to child view button
                  IconButton(
                    onPressed: onSwitchToChild,
                    icon: Icon(
                      Icons.switch_account,
                      color: AppColors.paperAccent,
                    ),
                    tooltip: '학생 화면으로 전환',
                  ),
                  // Edit button
                  IconButton(
                    onPressed: onTap,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.inkSecondary,
                    ),
                    tooltip: '정보 수정',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
