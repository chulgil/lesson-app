import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academy/academy.dart';
import '../../../auth/auth_facade.dart';
import 'context_toggle_dialog.dart';

/// Profile-tab entry point for the owner ↔ teacher context toggle.
///
/// Watches the real available contexts (GET /auth/context). The toggle row is
/// only rendered when the user can actually switch (2+ contexts); single-context
/// users (and the loading/error states) render nothing.
class ContextToggleButton extends ConsumerWidget {
  const ContextToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextInfo = ref.watch(currentContextProvider);
    return contextInfo.maybeWhen(
      data: (info) {
        if (!info.canToggle) return const SizedBox.shrink();
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
          ),
          leading: const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.ink,
          ),
          title: Text(
            AppStrings.contextToggleButtonLabel,
            style: AppTypography.bodyMedium,
          ),
          subtitle: Text(
            AppStrings.contextToggleButtonSubtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.inkSecondary,
          ),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => const ContextToggleDialog(),
            );
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  /// Returns a [_MenuItem] for use in profile menu sections.
  ///
  /// Returns null if user doesn't have both roles. Retained for callers that
  /// build the profile menu from a flat list of [AcademyMember]s.
  // ignore: library_private_types_in_public_api
  static Future<_MenuItem?> buildMenuItem(
    BuildContext context,
    List<AcademyMember> academyMembers,
  ) async {
    // Check if user has both owner and teacher roles
    final hasOwnerRole = academyMembers.any(
      (m) => m.role == AcademyMemberRole.owner,
    );
    final hasTeacherRole = academyMembers.any(
      (m) => m.role == AcademyMemberRole.teacher,
    );

    if (!hasOwnerRole || !hasTeacherRole) {
      return null;
    }

    return _MenuItem(
      icon: Icons.swap_horiz_rounded,
      label: AppStrings.contextToggleButtonLabel,
      subtitle: AppStrings.contextToggleButtonSubtitle,
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => const ContextToggleDialog(),
        );
      },
    );
  }
}

/// Menu item data class for profile menu.
class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });
}
