import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/invite.dart';
import '../../../../providers/invite/invite_provider.dart';

/// Screen for viewing invite history
class InviteHistoryScreen extends ConsumerWidget {
  const InviteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myInvites = ref.watch(myInvitesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('초대 내역'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: myInvites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(error.toString()),
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
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '초대 내역을 불러오는 중 오류가 발생했습니다',
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              '생성한 초대가 없습니다',
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '초대 링크를 생성하면\n여기에 기록이 표시됩니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
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
          _buildSectionHeader('활성 초대', activeInvites.length),
          const SizedBox(height: AppSpacing.space3),
          ...activeInvites.map((invite) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _InviteCard(
                  invite: invite,
                  onRevoke: () => _handleRevoke(context, ref, invite),
                  onCopyCode: () => _copyCode(context, invite.inviteCode),
                ),
              )),
        ],
        if (activeInvites.isNotEmpty && inactiveInvites.isNotEmpty)
          const SizedBox(height: AppSpacing.space4),
        if (inactiveInvites.isNotEmpty) ...[
          _buildSectionHeader('만료/취소된 초대', inactiveInvites.length),
          const SizedBox(height: AppSpacing.space3),
          ...inactiveInvites.map((invite) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _InviteCard(
                  invite: invite,
                  isInactive: true,
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: AppTypography.caption.copyWith(
              color: AppColors.primary,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 취소'),
        content: const Text('이 초대 링크를 취소하시겠습니까?\n취소 후에는 이 코드로 연결할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(inviteRevokerProvider.notifier)
          .revokeInvite(invite.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대가 취소되었습니다')),
        );
      }
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대 코드가 복사되었습니다'),
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
        color: isInactive ? AppColors.backgroundLight : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isInactive
              ? AppColors.borderLight.withValues(alpha: 0.5)
              : AppColors.borderLight,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
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
                  color: AppColors.textSecondaryLight,
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
                  color: isInactive
                      ? AppColors.textSecondaryLight
                      : AppColors.textPrimaryLight,
                ),
              ),
              if (!isInactive && onCopyCode != null) ...[
                const SizedBox(width: AppSpacing.space2),
                IconButton(
                  onPressed: onCopyCode,
                  icon: Icon(Icons.copy, size: 18, color: AppColors.primary),
                  tooltip: '코드 복사',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 14,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${invite.useCount}회 사용',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (!isInactive) ...[
                const SizedBox(width: AppSpacing.space3),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  invite.formattedExpiry,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
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
                color: AppColors.textSecondaryLight,
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
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: const Text('초대 취소'),
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
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
