// Level up celebration dialog.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Shows a level-up celebration dialog.
Future<void> showLevelUpDialog(
  BuildContext context, {
  required int newLevel,
  required String levelTitle,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LevelUpDialog(
      newLevel: newLevel,
      levelTitle: levelTitle,
    ),
  );
}

/// Level up celebration dialog widget.
class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final String levelTitle;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.levelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.paperAccent,
                    AppColors.paperAccent.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.paperAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Lv.$newLevel',
                style: AppTypography.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Title
            Text(
              '레벨 업!',
              style: AppTypography.headingLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            // Level title
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Text(
                levelTitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space3),

            // Congratulations text
            Text(
              '축하합니다! 꾸준한 연습으로\n새로운 레벨에 도달했어요!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('계속하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
