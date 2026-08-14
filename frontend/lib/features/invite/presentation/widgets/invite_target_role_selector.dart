import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../profile/domain/entities/invite.dart';
import '../../../profile/presentation/extensions/profile_domain_visuals.dart';

/// Target-role picker shown before an invite is generated (#1267).
///
/// 3-card selector consistent with [RoleSelectScreen]'s card idiom (icon
/// circle + title + description, single tap selects and proceeds) — tapping
/// a card immediately creates the invite with that target role via
/// [onSelect].
class InviteTargetRoleSelector extends StatelessWidget {
  const InviteTargetRoleSelector({
    super.key,
    required this.onSelect,
    this.isLoading = false,
  });

  final ValueChanged<InviteTargetRole> onSelect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.inviteTargetRoleSelectorTitle,
          style: NotebookTypography.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          AppStrings.inviteTargetRoleSelectorSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space6),
        for (final role in InviteTargetRole.values) ...[
          _TargetRoleCard(
            role: role,
            isLoading: isLoading,
            onTap: () => onSelect(role),
          ),
          if (role != InviteTargetRole.values.last)
            const SizedBox(height: AppSpacing.space3),
        ],
      ],
    );
  }
}

class _TargetRoleCard extends StatelessWidget {
  const _TargetRoleCard({
    required this.role,
    required this.isLoading,
    required this.onTap,
  });

  final InviteTargetRole role;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.paperAccent.withValues(alpha: 0.3),
          ),
          color: AppColors.paperAccent.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
              ),
              child: Icon(role.icon, color: AppColors.paperAccent, size: 24),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    role.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.paperAccent),
          ],
        ),
      ),
    );
  }
}
