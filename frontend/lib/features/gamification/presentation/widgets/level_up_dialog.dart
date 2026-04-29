// Level up celebration dialog.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// Shows a level-up celebration dialog.
Future<void> showLevelUpDialog(
  BuildContext context, {
  required int newLevel,
  required String levelTitle,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => LevelUpDialog(newLevel: newLevel, levelTitle: levelTitle),
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
        borderRadius: BorderRadius.zero,
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
                    AppColors.paperAccent,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.paperAccent,
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Lv.$newLevel',
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space5),

            // Notebook × Score: 다이얼로그 헤드라인 §7.89 변형 + 정적 명사 → Playfair 승격.
            Text(
              '레벨 업!',
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.paperAccent,
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
                color: AppColors.paperAccentSoft,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                levelTitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.paperAccent,
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
