import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Notification bell icon with badge for parent dashboard
class ParentNotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const ParentNotificationBadge({super.key, this.count = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap ?? () {},
          icon: Icon(
            count > 0 ? Icons.notifications : Icons.notifications_outlined,
            color: count > 0 ? AppColors.primary : AppColors.inkSecondary,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space1),
              decoration: BoxDecoration(
                color: AppColors.paperAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: AppTypography.captionSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
