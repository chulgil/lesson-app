import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Profile photo section with optional edit button.
class StudentProfileSection extends StatelessWidget {
  final String displayName;
  final VoidCallback? onTapPhoto;

  const StudentProfileSection({
    super.key,
    required this.displayName,
    this.onTapPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : '?',
                  // Notebook × Score §7.30 Gothic 유지 + §7.50 soft vermillion 배경 → 전경 paper.
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.paper,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onTapPhoto != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent,
                      shape: BoxShape.circle,
                      // Notebook × Score §7.50: Vermillion edit badge border/icon = paper.
                      border: Border.all(color: AppColors.paper, width: 2),
                    ),
                    child: IconButton(
                      onPressed: onTapPhoto,
                      icon: const Icon(
                        Icons.camera_alt,
                        color: AppColors.paper,
                      ),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
          if (onTapPhoto != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '프로필 사진 변경',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
