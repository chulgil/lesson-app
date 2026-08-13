import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../auth/auth_facade.dart';
import '../../domain/entities/child_profile.dart';
import '../extensions/parent_home_domain_visuals.dart';
import '../providers/child_profile_provider.dart';
import '../widgets/child_profile_actions_bottom_sheet.dart';
import 'child_profile_form_screen.dart';

/// Screen for managing child profiles (under-14 students)
class ChildProfilesScreen extends ConsumerWidget {
  final String parentId;

  const ChildProfilesScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve from the authenticated user when no parentId was passed, instead
    // of falling back to the 'parent_1' mock seed id. (#586)
    final pid =
        parentId.isNotEmpty ? parentId : ref.watch(currentUserIdProvider);
    final profilesAsync = ref.watch(childProfilesProvider(pid));

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.parentHomeChildManagement,
        actions: const [DetailAppBarAction.add],
        onAction: (_) => _navigateToAddChild(context, pid),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => ErrorStateWidget(
              title: AppStrings.errorOccurred,
              actionLabel: AppStrings.retry,
              onAction: () => ref.invalidate(childProfilesProvider(pid)),
            ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildProfileList(context, ref, profiles, pid);
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
              AppStrings.parentHomeChildrenEmptySubtitle,
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
    String pid,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _ChildProfileCard(
          profile: profile,
          onTap: () => _showActionsSheet(context, ref, profile, pid),
        );
      },
    );
  }

  /// 자녀 카드 탭 → 2 액션 BottomSheet (#660 C7).
  /// SwipeAction destructive 메타포가 부적절해 swipe 패턴 대신 채택.
  Future<void> _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    ChildProfile profile,
    String pid,
  ) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (sheetContext) => ChildProfileActionsBottomSheet(
            profile: profile,
            onEditProfile: () => _navigateToEditChild(context, profile, pid),
          ),
    );
  }

  void _navigateToAddChild(BuildContext context, String pid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildProfileFormScreen(parentId: pid),
      ),
    );
  }

  void _navigateToEditChild(
    BuildContext context,
    ChildProfile profile,
    String pid,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ChildProfileFormScreen(parentId: pid, existingProfile: profile),
      ),
    );
  }

}

class _ChildProfileCard extends StatelessWidget {
  final ChildProfile profile;
  final VoidCallback onTap;

  const _ChildProfileCard({required this.profile, required this.onTap});

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
                        Flexible(
                          child: Text(
                            profile.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            AppStrings.parentHomeAgeFormat(profile.age),
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
                          Flexible(
                            child: Text(
                              profile.teacherName!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions — Column 2 버튼 제거 (#660 C7).
              // 행 탭 → ChildProfileActionsBottomSheet 으로 통합.
              Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
