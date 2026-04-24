// Language selection bottom sheet.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';

/// Bottom sheet for language selection (MVP: Korean only).
class LanguageSelectSheet extends StatelessWidget {
  const LanguageSelectSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSelectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

              const SizedBox(height: AppSpacing.space5),

              // Notebook × Score: 시트 헤더는 Playfair sectionTitle (§7.87-f / §7.27).
              Text('언어 설정', style: NotebookTypography.sectionTitle),

              const SizedBox(height: AppSpacing.space6),

              // Korean - selected
              _buildLanguageItem(
                context,
                flag: '🇰🇷',
                name: '한국어',
                isSelected: true,
                onTap: () => Navigator.pop(context),
              ),

              const SizedBox(height: AppSpacing.space2),

              // English - coming soon
              _buildLanguageItem(
                context,
                flag: '🇺🇸',
                name: 'English',
                isSelected: false,
                isComingSoon: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('English will be supported soon'),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.space2),

              // Japanese - coming soon
              _buildLanguageItem(
                context,
                flag: '🇯🇵',
                name: '日本語',
                isSelected: false,
                isComingSoon: true,
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('日本語は準備中です')));
                },
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context, {
    required String flag,
    required String name,
    required bool isSelected,
    bool isComingSoon = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paperDark,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isComingSoon ? AppColors.inkTertiary : AppColors.ink,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.paperAccent, size: 22),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.inkTertiary.withValues(alpha: 0.1),
                ),
                child: Text(
                  '준비 중',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
