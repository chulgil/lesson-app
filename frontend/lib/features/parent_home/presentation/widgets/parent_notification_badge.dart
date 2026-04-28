import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
            color: count > 0 ? AppColors.paperAccent : AppColors.inkSecondary,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            // §7.132 / §7.131: 둥근 뱃지 → 사각 잉크 마크. paperAccent 배경 + paper 테두리.
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.paperAccent,
                border: Border.all(color: AppColors.paper, width: 1),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.paper,
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
