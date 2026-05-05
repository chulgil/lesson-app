import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';

/// Screen for viewing invite history
class InviteHistoryScreen extends ConsumerWidget {
  const InviteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myInvites = ref.watch(myInvitesProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: const Text(AppStrings.inviteHistoryTooltip),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: myInvites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(AppStrings.inviteHistoryLoadErrorRetry),
        data: (invites) {
          if (invites.isEmpty) {
            return _buildEmpty();
          }
          return _buildInvitesList(context, ref, invites);
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.inviteHistoryLoadErrorDescription,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(
                Icons.history,
                size: 40,
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            // Notebook × Score: 빈 상태 3축(§7.89) + 정적 명사 단일 헤드라인 → §7.17 승격.
            Text(
              AppStrings.inviteHistoryEmptyTitle,
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.inviteHistoryEmptyBody,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesList(
    BuildContext context,
    WidgetRef ref,
    List<Invite> invites,
  ) {
    // Separate active and inactive invites
    final activeInvites = invites.where((i) => i.isValid).toList();
    final inactiveInvites = invites.where((i) => !i.isValid).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        if (activeInvites.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.inviteHistoryActiveSection,
            activeInvites.length,
          ),
          const SizedBox(height: AppSpacing.space3),
          ...activeInvites.map(
            (invite) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: _InviteCard(
                invite: invite,
                onRevoke: () => _handleRevoke(context, ref, invite),
                onCopyCode: () => _copyCode(context, invite.inviteCode),
              ),
            ),
          ),
        ],
        if (activeInvites.isNotEmpty && inactiveInvites.isNotEmpty)
          const SizedBox(height: AppSpacing.space4),
        if (inactiveInvites.isNotEmpty) ...[
          _buildSectionHeader(
            AppStrings.inviteHistoryInactiveSection,
            inactiveInvites.length,
          ),
          const SizedBox(height: AppSpacing.space3),
          ...inactiveInvites.map(
            (invite) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: _InviteCard(invite: invite, isInactive: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        // Notebook × Score: 초대 섹션 헤더 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(title, style: NotebookTypography.sectionTitle),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            borderRadius: BorderRadius.zero,
          ),
          child: Text(
            count.toString(),
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRevoke(
    BuildContext context,
    WidgetRef ref,
    Invite invite,
  ) async {
    final confirmed = await showNotebookDialog(
      context: context,
      title: AppStrings.inviteRevokeDialogTitle,
      message: AppStrings.inviteRevokeDialogContent,
      confirmLabel: AppStrings.cancelRequestAction,
      cancelLabel: AppStrings.inviteRevokeDialogNo,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(inviteRevokerProvider.notifier)
          .revokeInvite(invite.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.inviteRevokedSnack)),
        );
      }
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.inviteCodeCopiedSnack),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Invite invite;
  final bool isInactive;
  final VoidCallback? onRevoke;
  final VoidCallback? onCopyCode;

  const _InviteCard({
    required this.invite,
    this.isInactive = false,
    this.onRevoke,
    this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: isInactive ? AppColors.paperDark : AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color:
              isInactive
                  ? AppColors.inkQuaternary.withValues(alpha: 0.5)
                  : AppColors.inkQuaternary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: invite.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  invite.status.label,
                  style: AppTypography.caption.copyWith(
                    color: invite.status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Created date
              Text(
                _formatDate(invite.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Text(
                invite.inviteCode,
                style: AppTypography.headingMedium.copyWith(
                  letterSpacing: 4,
                  color: isInactive ? AppColors.inkSecondary : AppColors.ink,
                ),
              ),
              if (!isInactive && onCopyCode != null) ...[
                const SizedBox(width: AppSpacing.space2),
                IconButton(
                  onPressed: onCopyCode,
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: AppColors.paperAccent,
                  ),
                  tooltip: AppStrings.inviteCodeCopyTooltip,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.space1),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(Icons.people, size: 14, color: AppColors.inkSecondary),
              const SizedBox(width: AppSpacing.space1),
              Text(
                AppStrings.inviteUseCountFormat(invite.useCount),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              if (!isInactive) ...[
                const SizedBox(width: AppSpacing.space3),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.inkSecondary,
                ),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  invite.formattedExpiry,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (invite.note != null && invite.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              invite.note!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (!isInactive && onRevoke != null) ...[
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRevoke,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  side: BorderSide(color: AppColors.paperAccent),
                ),
                child: const Text(AppStrings.inviteRevokeDialogTitle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return AppStrings.todayLabel;
    } else if (diff.inDays == 1) {
      return AppStrings.yesterdayLabel;
    } else if (diff.inDays < 7) {
      return AppStrings.timeAgoDays(diff.inDays);
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
