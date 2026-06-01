import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../domain/entities/pending_invite.dart';
import '../providers/invite_pending_provider.dart';

/// 선생님 초대 대기 리스트 — #5 D-G3 Phase 2.
///
/// 3 섹션 (만료 임박 D+5~ / D+3 이상 / D+0~2) + 각 행의 [재발송] 버튼.
class InvitePendingListScreen extends ConsumerWidget {
  const InvitePendingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingInviteListProvider);
    return NotebookScreenScaffold(
      appBarTitle: AppStrings.invitePendingListTitle,
      body: pendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text(AppStrings.invitePendingEmpty));
          }
          return _Sections(items: items);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => const Center(child: Text(AppStrings.invitePendingEmpty)),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.items});

  final List<PendingInvite> items;

  @override
  Widget build(BuildContext context) {
    final imminent = items.where((e) => e.isImminent).toList();
    final urgent = items.where((e) => e.isUrgent).toList();
    final recent = items.where((e) => !e.isImminent && !e.isUrgent).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      children: [
        if (imminent.isNotEmpty)
          _Group(
            title: AppStrings.invitePendingSectionImminent,
            items: imminent,
          ),
        if (urgent.isNotEmpty)
          _Group(title: AppStrings.invitePendingSectionUrgent, items: urgent),
        if (recent.isNotEmpty)
          _Group(title: AppStrings.invitePendingSectionRecent, items: recent),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});

  final String title;
  final List<PendingInvite> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: Text(
            title,
            style: NotebookTypography.eyebrow.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        ...items.map((p) => _Row(item: p)),
      ],
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.item});

  final PendingInvite item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${AppStrings.invitePendingCodeLabel} ${item.inviteCode}',
                      style: NotebookTypography.sectionTitle.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      item.daysSinceSent == 0
                          ? '방금'
                          : 'D+${item.daysSinceSent}',
                      style: NotebookTypography.eyebrow.copyWith(
                        color:
                            item.isImminent
                                ? AppColors.paperAccent
                                : item.isUrgent
                                ? AppColors.paperTrial
                                : AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    item.note!,
                    style: NotebookTypography.fine.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.resentCount > 0) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '재발송 ${item.resentCount}회',
                    style: NotebookTypography.fine.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          FilledButton(
            onPressed: item.canResend ? () => _resend(context, ref) : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
              backgroundColor: AppColors.paperAccent,
            ),
            child: const Text(AppStrings.invitePendingResendLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _resend(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(invitePendingActionsProvider).resend(item.inviteId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.invitePendingResendSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString();
      final friendly =
          message.contains('cooldown') || message.contains('10')
              ? AppStrings.invitePendingResendCooldown
              : AppStrings.invitePendingResendFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    }
  }
}
