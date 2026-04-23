// App info screen showing version, licenses, and legal links.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';

/// App information screen.
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('앱 정보')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.space6),

          // App icon and version
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 40,
                    color: AppColors.paper,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 브랜드 타이틀은 Playfair masthead (§7.87-f).
                Text('Lessonaza', style: NotebookTypography.masthead),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '버전 1.0.0 (1)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Menu items
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.space4 + 36 + AppSpacing.space3,
                  color: AppColors.inkQuaternary,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보처리방침',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.space4 + 36 + AppSpacing.space3,
                  color: AppColors.inkQuaternary,
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.source_outlined,
                  title: '오픈소스 라이선스',
                  onTap:
                      () => showLicensePage(
                        context: context,
                        applicationName: 'Lessonaza',
                        applicationVersion: '1.0.0',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space4),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLarge,
                              ),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: AppColors.paper,
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space8),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  '\u00a9 2026 Lessonaza',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'Made with \u2665',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(icon, size: 20, color: AppColors.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
