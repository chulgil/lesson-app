import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/child_profile.dart';
import '../providers/child_profile_provider.dart';
import 'child_profile_form_screen.dart';

/// Screen for managing child profiles (under-14 students)
class ChildProfilesScreen extends ConsumerWidget {
  final String parentId;

  const ChildProfilesScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider(parentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('자녀 관리'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _navigateToAddChild(context),
            icon: const Icon(Icons.add),
            tooltip: '자녀 추가',
          ),
        ],
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
                  Text('오류가 발생했습니다', style: AppTypography.bodyLarge),
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
            Text('등록된 자녀가 없습니다', style: NotebookTypography.sectionTitle),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '만 14세 미만 자녀를 추가하여\n레슨 일정과 연습 현황을 관리해보세요',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddChild(context),
              icon: const Icon(Icons.add),
              label: const Text('자녀 추가하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space3,
                ),
              ),
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
      itemCount: profiles.length + 1, // +1 for add button at end
      itemBuilder: (context, index) {
        if (index == profiles.length) {
          return _buildAddChildButton(context);
        }
        return _ChildProfileCard(
          profile: profiles[index],
          onTap: () => _navigateToEditChild(context, profiles[index]),
          onSwitchToChild:
              () => _switchToChildView(context, ref, profiles[index]),
        );
      },
    );
  }

  Widget _buildAddChildButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space3),
      child: OutlinedButton.icon(
        onPressed: () => _navigateToAddChild(context),
        icon: const Icon(Icons.add),
        label: const Text('자녀 추가하기'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
          side: BorderSide(color: AppColors.paperAccent),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        ),
      ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Profile avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: profile.profileColor,
                child: Text(
                  profile.initial,
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
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
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSmall,
                            ),
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
