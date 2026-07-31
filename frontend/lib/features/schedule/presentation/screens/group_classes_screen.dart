// Teacher's own group classes (P1-1)
//
// Row actions follow the swipe contract (C6): right-to-left reveals the two
// management actions (edit, take down) — no trailing icon buttons or popup
// menus duplicating them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/group_class.dart';
import '../providers/group_class_providers.dart';
import 'group_class_form_screen.dart';

/// The teacher's group classes — 반 and 드롭인 in one list.
class GroupClassesScreen extends ConsumerWidget {
  const GroupClassesScreen({
    super.key,
    required this.teacherId,
    required this.onOpenClass,
  });

  final String teacherId;

  /// Opens the class detail screen. That screen needs a concrete session, which
  /// this list does not hold — J12 resolves it when wiring the route.
  final void Function(GroupClass groupClass) onOpenClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherGroupClassesProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.groupClassesTitle,
        actions: const [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) _openForm(context);
        },
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => _ErrorView(
              onRetry:
                  () => ref.invalidate(teacherGroupClassesProvider(teacherId)),
            ),
        data: (classes) {
          if (classes.isEmpty) {
            // Create lives in the app bar only — header_primary_action_contract
            // forbids a second add CTA in the body.
            return const EmptyStateWidget(
              icon: Icons.groups_outlined,
              title: AppStrings.groupClassesEmptyTitle,
              subtitle: AppStrings.groupClassesEmptySubtitle,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: classes.length,
            separatorBuilder:
                (_, __) => const SizedBox(height: AppSpacing.space3),
            itemBuilder: (context, index) {
              final groupClass = classes[index];
              return SwipeActionTile(
                actions: [
                  SwipeAction(
                    label: AppStrings.swipeActionEdit,
                    icon: Icons.edit_outlined,
                    onPressed: () => _openForm(context, groupClass: groupClass),
                  ),
                  SwipeAction(
                    label: AppStrings.groupClassesDeactivateAction,
                    icon: Icons.archive_outlined,
                    tone: SwipeActionTone.destructive,
                    onPressed:
                        () => _confirmDeactivate(context, ref, groupClass),
                  ),
                ],
                child: GroupClassRow(
                  groupClass: groupClass,
                  onTap: () => onOpenClass(groupClass),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {GroupClass? groupClass}) {
    // Same-feature sibling screen; J12 may swap this for a named route once the
    // form path is registered.
    Navigator.of(context).push(
      MaterialPageRoute<GroupClass>(
        builder:
            (_) => GroupClassFormScreen(
              teacherId: teacherId,
              groupClass: groupClass,
            ),
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    GroupClass groupClass,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.groupClassesDeactivateTitle,
      content: Text(AppStrings.groupClassesDeactivateMessage(groupClass.name)),
      confirmLabel: AppStrings.groupClassesDeactivateAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(groupClassFormNotifierProvider.notifier)
          .deactivate(teacherId: teacherId, classId: groupClass.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassesDeactivated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassesDeactivateFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }
}

/// One class in the list: name, type badge, schedule and capacity summary.
class GroupClassRow extends StatelessWidget {
  const GroupClassRow({
    super.key,
    required this.groupClass,
    required this.onTap,
  });

  final GroupClass groupClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(
                    label:
                        groupClass.type == GroupClassType.regular
                            ? AppStrings.groupClassRegular
                            : AppStrings.groupClassDropin,
                  ),
                  if (!groupClass.isActive) ...[
                    const SizedBox(width: AppSpacing.space2),
                    const _Badge(label: AppStrings.groupClassesInactiveBadge),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                groupClass.name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      groupClass.isActive
                          ? AppColors.ink
                          : AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                _summary,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Repeat rule (regular) or duration (drop-in), plus the class capacity.
  /// Capacity comes from the class, never from a session (P1-0 SSOT).
  String get _summary {
    final parts = <String>[];
    final days = groupClass.repeatDaysOfWeek;
    final time = groupClass.repeatTimeOfDay;
    if (groupClass.type == GroupClassType.regular &&
        days != null &&
        days.isNotEmpty &&
        time != null) {
      final dayLabels = (days.toList()..sort())
          .map(LessonDateUtils.getWeekdayNameKorean)
          .join(', ');
      parts.add(AppStrings.groupClassesRepeatSummary(dayLabels, time));
    }
    parts.add(AppStrings.durationMinutesValue(groupClass.durationMinutes));
    parts.add(AppStrings.groupClassesCapacitySummary(groupClass.maxCapacity));
    return parts.join(' · ');
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: const BoxDecoration(color: AppColors.paperAccentSoft),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: AppStrings.loadDataFailed,
      actionLabel: AppStrings.retry,
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}
