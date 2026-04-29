import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Role selection card shown in the role-select bottom sheet
class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Notebook × Score §7.113: 역할 카드(바텀시트) 는 BorderRadius.zero (악보·종이 직선 기하).
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              // Notebook × Score §7.113: 아이콘 bg 도 각진 (카드 내부 컨테이너 규칙).
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
              ),
              child: Icon(icon, color: AppColors.paperAccent),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
