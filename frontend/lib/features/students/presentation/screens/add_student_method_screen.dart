import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Screen for selecting student registration method
class AddStudentMethodScreen extends StatelessWidget {
  const AddStudentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.studentAddLabel,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.studentAddMethodQuestion,
                // Notebook × Score §7.17: 화면 레벨 질문 타이틀 = Playfair sectionTitle.
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space6),

              // Invite card (recommended)
              _MethodCard(
                icon: Icons.mail_outline,
                title: AppStrings.studentInviteTitle,
                badge: '권장',
                description: '학생에게 초대 링크를 보내면\n학생 정보가 자동으로 등록됩니다.',
                buttonText: '초대하기',
                isPrimary: true,
                onTap: () {
                  context.push(AppRoutes.invite);
                },
              ),

              const SizedBox(height: AppSpacing.space4),

              // Direct registration card
              _MethodCard(
                icon: Icons.edit_note,
                title: AppStrings.studentDirectRegister,
                description: '학생 정보를 직접 입력하여\n관리할 수 있습니다.',
                buttonText: '작성하기',
                isPrimary: false,
                onTap: () {
                  context.push(AppRoutes.addStudent);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final String description;
  final String buttonText;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    this.badge,
    required this.description,
    required this.buttonText,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isPrimary
                ? AppColors.paperAccentSoft
                : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isPrimary ? AppColors.paperAccent : AppColors.inkQuaternary,
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color:
                        isPrimary
                            ? AppColors.paperAccentSoft
                            : AppColors.paperDark,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color:
                        isPrimary
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPrimary ? AppColors.paperAccent : AppColors.ink,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.paperAccent,
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.captionSmall.copyWith(
                        // Notebook × Score §7.50: Vermillion badge foreground = paper.
                        color: AppColors.paper,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Description
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: AppSpacing.space4),

            // Button
            SizedBox(
              width: double.infinity,
              child:
                  isPrimary
                      ? FilledButton(onPressed: onTap, child: Text(buttonText))
                      : OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.paperAccent,
                          side: const BorderSide(color: AppColors.paperAccent),
                        ),
                        child: Text(buttonText),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
