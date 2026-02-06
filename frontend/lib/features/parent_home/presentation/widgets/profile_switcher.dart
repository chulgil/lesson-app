import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/child_profile.dart';
import '../../../../models/user_profile.dart';
import '../../../../providers/parent/user_profile_provider.dart';

/// Profile switcher widget for switching between parent, student, and child profiles
///
/// Shows a dropdown button with available profiles and allows switching.
/// Can be placed in AppBar or other locations.
class ProfileSwitcher extends ConsumerWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSwitch = ref.watch(canSwitchProfilesProvider);

    if (!canSwitch) {
      // Only one profile available, show simple display
      return const _SingleProfileDisplay();
    }

    return const _ProfileDropdown();
  }
}

class _SingleProfileDisplay extends ConsumerWidget {
  const _SingleProfileDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            userProfile.activeProfile.icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            userProfile.activeProfileDisplayName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDropdown extends ConsumerWidget {
  const _ProfileDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final availableProfiles = ref.watch(availableProfileTypesProvider);

    return PopupMenuButton<_ProfileOption>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      onSelected: (option) => _handleProfileSwitch(ref, option),
      itemBuilder: (context) => _buildMenuItems(userProfile, availableProfiles),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              userProfile.activeProfile.icon,
              size: 20,
              color: userProfile.activeProfile.color,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              userProfile.activeProfileDisplayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<_ProfileOption>> _buildMenuItems(
    UserProfile userProfile,
    List<ProfileType> availableProfiles,
  ) {
    final items = <PopupMenuEntry<_ProfileOption>>[];

    // Parent profile option
    if (availableProfiles.contains(ProfileType.parent)) {
      items.add(_buildProfileItem(
        option: _ProfileOption(
          type: ProfileType.parent,
          label: '학부모',
          icon: ProfileType.parent.icon,
          color: ProfileType.parent.color,
        ),
        isSelected: userProfile.activeProfile == ProfileType.parent,
      ));
    }

    // Student profile option
    if (availableProfiles.contains(ProfileType.student)) {
      items.add(_buildProfileItem(
        option: _ProfileOption(
          type: ProfileType.student,
          label: '${userProfile.userName} (학생)',
          icon: ProfileType.student.icon,
          color: ProfileType.student.color,
          subtitle: userProfile.studentTeacherName != null
              ? '${userProfile.studentTeacherName} 선생님'
              : null,
        ),
        isSelected: userProfile.activeProfile == ProfileType.student,
      ));
    }

    // Child profile options
    if (availableProfiles.contains(ProfileType.child) &&
        userProfile.children.isNotEmpty) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<_ProfileOption>(
          enabled: false,
          height: 30,
          child: Text(
            '자녀 프로필',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      for (final child in userProfile.children) {
        items.add(_buildProfileItem(
          option: _ProfileOption(
            type: ProfileType.child,
            childId: child.id,
            label: child.name,
            icon: ProfileType.child.icon,
            color: child.profileColor,
            subtitle: _getChildSubtitle(child),
            badge: child.isUnconnected ? '미연결' : null,
            badgeColor: child.connectionStatus.color,
          ),
          isSelected: userProfile.activeProfile == ProfileType.child &&
              userProfile.activeChildId == child.id,
        ));
      }
    }

    return items;
  }

  String? _getChildSubtitle(ChildProfile child) {
    if (child.isConnected && child.teacherName != null) {
      return '${child.teacherName} 선생님';
    }
    if (child.isPending) {
      return '연결 대기 중';
    }
    if (child.isUnconnected) {
      return '연습/메트로놈만 가능';
    }
    return child.instrumentLabel;
  }

  PopupMenuItem<_ProfileOption> _buildProfileItem({
    required _ProfileOption option,
    required bool isSelected,
  }) {
    return PopupMenuItem<_ProfileOption>(
      value: option,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: option.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              option.icon,
              size: 18,
              color: option.color,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (option.badge != null) ...[
                      const SizedBox(width: AppSpacing.space1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: option.badgeColor?.withValues(alpha: 0.1) ??
                              AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          option.badge!,
                          style: TextStyle(
                            fontSize: 10,
                            color: option.badgeColor ?? AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (option.subtitle != null)
                  Text(
                    option.subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check,
              size: 18,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  void _handleProfileSwitch(WidgetRef ref, _ProfileOption option) {
    final notifier = ref.read(currentUserProfileProvider.notifier);

    switch (option.type) {
      case ProfileType.parent:
        notifier.switchToParent();
        break;
      case ProfileType.student:
        notifier.switchToStudent();
        break;
      case ProfileType.child:
        if (option.childId != null) {
          notifier.switchToChild(option.childId!);
        }
        break;
    }
  }
}

/// Internal class for profile option data
class _ProfileOption {
  final ProfileType type;
  final String? childId;
  final String label;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;

  const _ProfileOption({
    required this.type,
    this.childId,
    required this.label,
    required this.icon,
    required this.color,
    this.subtitle,
    this.badge,
    this.badgeColor,
  });
}

/// Compact profile switcher for use in more constrained spaces
class ProfileSwitcherCompact extends ConsumerWidget {
  const ProfileSwitcherCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final canSwitch = ref.watch(canSwitchProfilesProvider);

    return GestureDetector(
      onTap: canSwitch
          ? () => _showProfileBottomSheet(context, ref)
          : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: userProfile.activeProfile.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: userProfile.activeProfile.color.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          userProfile.activeProfile.icon,
          size: 20,
          color: userProfile.activeProfile.color,
        ),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLarge)),
      ),
      builder: (context) => const ProfileSwitcherBottomSheet(),
    );
  }
}

/// Bottom sheet for profile switching
class ProfileSwitcherBottomSheet extends ConsumerWidget {
  const ProfileSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final availableProfiles = ref.watch(availableProfileTypesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '프로필 전환',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Parent option
            if (availableProfiles.contains(ProfileType.parent))
              _ProfileTile(
                label: '학부모',
                subtitle: '자녀 관리',
                icon: ProfileType.parent.icon,
                color: ProfileType.parent.color,
                isSelected: userProfile.activeProfile == ProfileType.parent,
                onTap: () {
                  ref.read(currentUserProfileProvider.notifier).switchToParent();
                  Navigator.pop(context);
                },
              ),

            // Student option
            if (availableProfiles.contains(ProfileType.student))
              _ProfileTile(
                label: '${userProfile.userName} (학생)',
                subtitle: userProfile.studentTeacherName != null
                    ? '${userProfile.studentTeacherName} 선생님'
                    : '본인 연습',
                icon: ProfileType.student.icon,
                color: ProfileType.student.color,
                isSelected: userProfile.activeProfile == ProfileType.student,
                onTap: () {
                  ref.read(currentUserProfileProvider.notifier).switchToStudent();
                  Navigator.pop(context);
                },
              ),

            // Children
            if (userProfile.children.isNotEmpty) ...[
              const Divider(height: AppSpacing.space6),
              const Text(
                '자녀 프로필',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              ...userProfile.children.map((child) => _ProfileTile(
                    label: child.name,
                    subtitle: child.isUnconnected
                        ? '연습/메트로놈만 가능'
                        : child.teacherName ?? child.instrumentLabel,
                    icon: ProfileType.child.icon,
                    color: child.profileColor,
                    isSelected: userProfile.activeProfile == ProfileType.child &&
                        userProfile.activeChildId == child.id,
                    badge: child.isUnconnected ? '미연결' : null,
                    badgeColor: child.connectionStatus.color,
                    onTap: () {
                      ref
                          .read(currentUserProfileProvider.notifier)
                          .switchToChild(child.id);
                      Navigator.pop(context);
                    },
                  )),
            ],

            const SizedBox(height: AppSpacing.space3),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.space1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor?.withValues(alpha: 0.1) ??
                                AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              color: badgeColor ?? AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
