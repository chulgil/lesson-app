import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';

/// 홈 화면 우하단 고정 퀵액션 FAB.
///
/// 탭 시 '레슨 추가' / '학생 추가' 옵션이 담긴 바텀시트를 표시한다.
/// 라우트: [AppRoutes.addLesson], [AppRoutes.addStudent].
class HomeQuickActionFab extends StatelessWidget {
  const HomeQuickActionFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: AppStrings.homeQuickActionFabTooltip,
      backgroundColor: AppColors.paperAccent,
      foregroundColor: AppColors.paper,
      shape: const CircleBorder(),
      onPressed: () => _showQuickActionSheet(context),
      // 44px FAB (Hyen 표준 H8) 에 맞춘 비례 아이콘.
      child: const Icon(Icons.add, size: 22),
    );
  }

  Future<void> _showQuickActionSheet(BuildContext context) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      builder: (_) => const _QuickActionSheet(),
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionTile(
              icon: Icons.event_note_outlined,
              label: AppStrings.addLessonTooltip,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.addLesson);
              },
            ),
            const SizedBox(height: AppSpacing.space3),
            _ActionTile(
              icon: Icons.person_add_outlined,
              label: AppStrings.studentAddLabel,
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.addStudent);
              },
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.ink),
              const SizedBox(width: AppSpacing.space3),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
