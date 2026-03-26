import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// Card displaying a unified lesson request with approve/reject/negotiate actions.
class UnifiedRequestCard extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String? studentName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final VoidCallback? onProposeAlternatives;
  final void Function(int slotIndex)? onAcceptAlternative;
  final VoidCallback? onCounterPropose;

  const UnifiedRequestCard({
    super.key,
    required this.request,
    this.studentName,
    this.onApprove,
    this.onReject,
    this.onTap,
    this.onProposeAlternatives,
    this.onAcceptAlternative,
    this.onCounterPropose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.surfaceLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.space3),
              _buildDetails(),
              if (request.message != null && request.message!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                _buildMessage(),
              ],
              if (request.status == UnifiedRequestStatus.pending) ...[
                const SizedBox(height: AppSpacing.space4),
                _buildActions(),
              ],
              if (request.status == UnifiedRequestStatus.negotiating) ...[
                const SizedBox(height: AppSpacing.space3),
                _buildNegotiationSection(),
              ],
              if (request.status.isTerminal) ...[
                const SizedBox(height: AppSpacing.space3),
                _buildStatusBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: request.type == LessonRequestType.trial
                ? AppColors.infoLight
                : AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            request.type.label,
            style: AppTypography.caption.copyWith(
              color: request.type == LessonRequestType.trial
                  ? AppColors.info
                  : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (request.isReturningStudent) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '복귀',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          _formatRelativeTime(request.createdAt),
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student name + instrument
        Text(
          '${studentName ?? '학생'} · ${request.instrument}',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        // Goal + Experience + Preferred time
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _InfoChip(icon: Icons.flag_outlined, label: request.goal.label),
            _InfoChip(
              icon: Icons.bar_chart_outlined,
              label: request.experience.label,
            ),
            if (request.preferredDayLabel != null)
              _InfoChip(
                icon: Icons.schedule_outlined,
                label:
                    '${request.preferredDayLabel} ${request.preferredTime ?? ''}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        request.message!,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondaryLight,
              side: BorderSide(color: AppColors.borderLight),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('거절'),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onApprove,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('승인'),
          ),
        ),
      ],
    );
  }

  Widget _buildNegotiationSection() {
    final teacherProposals =
        request.proposals.where((p) => p.role == ProposerRole.teacher).toList();
    if (teacherProposals.isEmpty) return const SizedBox.shrink();

    final latestProposal = teacherProposals.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Round indicator
        Row(
          children: [
            Icon(Icons.swap_horiz, size: 16, color: AppColors.info),
            const SizedBox(width: 4),
            Text(
              '시간 협상 중 (${request.currentRound}/3 라운드)',
              style: AppTypography.caption.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        // Teacher's message
        if (latestProposal.message != null &&
            latestProposal.message!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              latestProposal.message!,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],

        // Alternative slot cards
        Text(
          '대안 시간',
          style: AppTypography.caption
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        ...latestProposal.slots.asMap().entries.map(
              (entry) => _AlternativeSlotCard(
                slot: entry.value,
                index: entry.key,
                onAccept: onAcceptAlternative != null
                    ? () => onAcceptAlternative!(entry.key)
                    : null,
              ),
            ),

        // Counter-propose button
        if (onCounterPropose != null) ...[
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCounterPropose,
              icon: const Icon(Icons.schedule, size: 16),
              label: const Text('다른 시간 제안'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
                side: BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ],

        // Teacher: propose alternatives button (for pending status handled above)
        if (onProposeAlternatives != null) ...[
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onProposeAlternatives,
              icon: const Icon(Icons.edit_calendar, size: 16),
              label: const Text('대안 시간 제안'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge() {
    final (color, bgColor) = switch (request.status) {
      UnifiedRequestStatus.approved ||
      UnifiedRequestStatus.timeConfirmed =>
        (AppColors.success, AppColors.successLight),
      UnifiedRequestStatus.rejected => (AppColors.error, AppColors.errorLight),
      UnifiedRequestStatus.cancelled ||
      UnifiedRequestStatus.expired =>
        (AppColors.textTertiaryLight, AppColors.backgroundLight),
      UnifiedRequestStatus.negotiating => (AppColors.info, AppColors.infoLight),
      _ => (AppColors.primary, AppColors.primaryLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        request.status.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    }
    return formatDateYMD(dateTime);
  }
}

class _AlternativeSlotCard extends StatelessWidget {
  final TimeSlotOption slot;
  final int index;
  final VoidCallback? onAccept;

  const _AlternativeSlotCard({
    required this.slot,
    required this.index,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: InkWell(
        onTap: onAccept,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${slot.dayLabel}요일 ${slot.startTime} - ${slot.endTime}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onAccept != null)
                Text(
                  '선택',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiaryLight),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
