import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/user_profile_provider.dart';

/// Profile header with avatar, name, email, and edit button
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          // Profile avatar
          Stack(
            children: [
              // §7.132: 프로필 아바타는 CircleAvatar 유지 (사람 = 원형 관습).
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.paperAccent,
                child: Text(
                  userProfile.userName.isNotEmpty
                      ? userProfile.userName.characters.first
                      : AppStrings.parentHomeAvatarInitialFallback,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
              // §7.132: 카메라 뱃지 round → 사각. white → paper.
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space1),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccent,
                    border: Border.all(color: AppColors.paper, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: AppColors.paper,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.space4),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userProfile.userName.isNotEmpty
                          ? userProfile.userName
                          : AppStrings.parentHomeParentLabel,
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    // §7.132: paperAccent.alpha → paperAccentSoft (cream 톤 정렬).
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccentSoft,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        AppStrings.parentHomeParentLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  userProfile.userId,
                  style: AppTypography.bodyMedium.copyWith(
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
