import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../lessons/lessons_facade.dart';

/// §13.2 — Show the common lesson action sheet.
///
/// All schedule views (daily timeline, weekly grid, monthly calendar)
/// must call this to ensure consistent actions.
///
/// Actions:
/// - Always: complete lesson
/// - Manual (no subscription): edit manual lesson
/// - Subscription + upcoming: schedule change (chat)
void showLessonActionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Lesson lesson,
}) {
  final hasSubscription = lesson.subscriptionId != null;
  final isUpcoming = lesson.isUpcoming;

  HapticFeedback.mediumImpact();

  showNotebookBottomSheet<void>(
    context: context,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder:
        (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                    decoration: BoxDecoration(color: AppColors.inkQuaternary),
                  ),
                ),
                // Student name + time
                Text(
                  '${lesson.studentName} · ${lesson.startTime}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                // §13.2 Complete lesson
                LessonActionCard(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.paperOk,
                  label: AppStrings.scheduleMarkComplete,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _completeLesson(context, ref, lesson);
                  },
                ),
                // Manual lesson → edit
                if (!hasSubscription) ...[
                  const SizedBox(height: AppSpacing.space2),
                  LessonActionCard(
                    icon: Icons.edit_calendar,
                    iconColor: AppColors.ink,
                    label: AppStrings.editManualFull,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(
                        AppRoutes.editLesson.replaceFirst(':id', lesson.id),
                      );
                    },
                  ),
                ],
                // Subscription lesson → edit content (notes/pieces only)
                if (hasSubscription) ...[
                  const SizedBox(height: AppSpacing.space2),
                  LessonActionCard(
                    icon: Icons.edit_note,
                    iconColor: AppColors.ink,
                    label: AppStrings.editContent,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(
                        AppRoutes.editLesson.replaceFirst(':id', lesson.id),
                      );
                    },
                  ),
                ],
                // Subscription + upcoming → schedule change (chat)
                if (hasSubscription && isUpcoming) ...[
                  const SizedBox(height: AppSpacing.space2),
                  LessonActionCard(
                    icon: Icons.swap_horiz,
                    iconColor: AppColors.ink,
                    label: AppStrings.scheduleChangeLabel,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push(
                        AppRoutes.subscriptionDetail.replaceFirst(
                          ':id',
                          lesson.subscriptionId!,
                        ),
                        extra: {'viewerRole': 'teacher'},
                      );
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
  );
}

Future<void> _completeLesson(
  BuildContext context,
  WidgetRef ref,
  Lesson lesson,
) async {
  try {
    final updated = lesson.copyWith(status: LessonStatus.completed);
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updated);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.scheduleCompleteFailed('$e'))),
      );
    }
  }
}

/// Notebook × Score action card — angular box, classic feel.
class LessonActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const LessonActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.inkTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
