// Cohort roster management for one group class (spec §2 P2-4)
//
// Teacher-only. Assignment is direct: the teacher picks one of their own
// students and the roster grows. Capacity belongs to the class (P1-0 SSOT), so
// a full roster hides the add action and the backend rejects an over-capacity
// assign as the backstop.
//
// Row actions follow the swipe contract (C6): right-to-left reveals the single
// management action (remove) — no trailing icon buttons duplicating it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/group_class_member.dart';
import '../providers/group_class_providers.dart';

/// The fixed roster of one 반 — who is in it, and add/remove.
class GroupClassMembersScreen extends ConsumerWidget {
  const GroupClassMembersScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupClass = ref.watch(groupClassByIdProvider(classId)).valueOrNull;
    final membersAsync = ref.watch(groupClassMembersProvider(classId));
    final members = membersAsync.valueOrNull;
    // Watched, not read: the roster renders before the student list resolves,
    // and rows that need it for their name have to rebuild when it lands.
    final students =
        ref.watch(studentsProvider).valueOrNull ?? const <Student>[];

    // Capacity is unknown until the class resolves — treat that as "not full"
    // and let the assign attempt surface the server's answer.
    final isFull =
        groupClass != null &&
        members != null &&
        members.length >= groupClass.maxCapacity;

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.groupClassMembersTitle,
        actions: [if (!isFull) DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            _openAssignPicker(context, ref, members ?? const [], students);
          }
        },
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => _ErrorView(
              onRetry: () => ref.invalidate(groupClassMembersProvider(classId)),
            ),
        data:
            (members) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (groupClass != null)
                  _CapacityHeader(
                    assigned: members.length,
                    capacity: groupClass.maxCapacity,
                    isFull: isFull,
                  ),
                Expanded(child: _roster(context, ref, members, students)),
              ],
            ),
      ),
    );
  }

  Widget _roster(
    BuildContext context,
    WidgetRef ref,
    List<GroupClassMember> members,
    List<Student> students,
  ) {
    if (members.isEmpty) {
      // Assign lives in the app bar only — header_primary_action_contract
      // forbids a second add CTA in the body.
      return const EmptyStateWidget(
        icon: Icons.group_outlined,
        title: AppStrings.groupClassMembersEmptyTitle,
        subtitle: AppStrings.groupClassMembersEmptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (context, index) {
        final member = members[index];
        final name = _displayName(member, students);
        return SwipeActionTile(
          actions: [
            SwipeAction(
              label: AppStrings.groupClassMembersRemoveAction,
              icon: Icons.person_remove_outlined,
              tone: SwipeActionTone.destructive,
              onPressed: () => _confirmRemove(context, ref, member, name),
            ),
          ],
          child: _MemberRow(name: name),
        );
      },
    );
  }

  /// Prefer the name the backend joined in; fall back to the teacher's own
  /// student list so a response without the join still reads as a person.
  String _displayName(GroupClassMember member, List<Student> students) {
    final fromServer = member.studentName;
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;

    for (final student in students) {
      if (student.id == member.studentId) return student.name;
    }
    return AppStrings.groupClassMembersUnknownStudent;
  }

  Future<void> _openAssignPicker(
    BuildContext context,
    WidgetRef ref,
    List<GroupClassMember> members,
    List<Student> students,
  ) async {
    final assigned = members.map((m) => m.studentId).toSet();
    final candidates = students.where((s) => !assigned.contains(s.id)).toList();

    final selected = await showNotebookModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignPickerSheet(candidates: candidates),
    );
    if (selected == null || !context.mounted) return;

    await _assign(context, ref, selected);
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(groupClassMemberNotifierProvider.notifier)
          .assign(classId: classId, studentId: student.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.groupClassMembersAssigned(student.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      // 400 = 정원 초과, 409 = 중복 배정 — 서버 문구가 그대로 사용자 안내다.
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassMembersAssignFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    GroupClassMember member,
    String name,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.groupClassMembersRemoveTitle,
      content: Text(AppStrings.groupClassMembersRemoveMessage(name)),
      confirmLabel: AppStrings.groupClassMembersRemoveAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(groupClassMemberNotifierProvider.notifier)
          .remove(classId: classId, studentId: member.studentId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassMembersRemoved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(AppStrings.groupClassMembersRemoveFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }
}

/// Assigned-vs-capacity summary, plus why the add action is gone when full.
class _CapacityHeader extends StatelessWidget {
  const _CapacityHeader({
    required this.assigned,
    required this.capacity,
    required this.isFull,
  });

  final int assigned;
  final int capacity;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space4,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.groupClassMembersCapacity(assigned, capacity),
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (isFull) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              AppStrings.groupClassMembersFullNotice,
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

/// One student on the roster.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Text(
          name,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Picks which of the teacher's students to put on the roster. Students already
/// assigned are filtered out by the caller, so every row here is assignable.
class _AssignPickerSheet extends StatelessWidget {
  const _AssignPickerSheet({required this.candidates});

  final List<Student> candidates;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder:
          (context, scrollController) => Column(
            children: [
              const SizedBox(height: AppSpacing.space2),
              const BottomSheetHandle(margin: EdgeInsets.zero),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Text(
                  AppStrings.groupClassMembersPickerTitle,
                  style: NotebookTypography.sectionTitle,
                ),
              ),
              Expanded(
                child:
                    candidates.isEmpty
                        ? const EmptyStateWidget(
                          icon: Icons.group_outlined,
                          title: AppStrings.groupClassMembersPickerEmptyTitle,
                          subtitle:
                              AppStrings.groupClassMembersPickerEmptySubtitle,
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          itemCount: candidates.length,
                          separatorBuilder: (_, __) => const ThinRule(),
                          itemBuilder: (context, index) {
                            final student = candidates[index];
                            return ListTile(
                              title: Text(student.name),
                              subtitle: Text(student.instrument),
                              onTap: () => Navigator.pop(context, student),
                            );
                          },
                        ),
              ),
            ],
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
