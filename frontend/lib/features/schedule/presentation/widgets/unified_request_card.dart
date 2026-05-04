import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';

import '../../../../core/l10n/app_strings.dart';
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
  final VoidCallback? onSendProposal;

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
    this.onSendProposal,
  });

  @override
  Widget build(BuildContext context) {
    return NotebookCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      shape: RoundedRectangleBorder(),
      elevation: 0,
      color: AppColors.paper,
      child: InkWell(
        onTap: onTap,
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
              if (request.status == UnifiedRequestStatus.timeConfirmed) ...[
                const SizedBox(height: AppSpacing.space3),
                _buildTimeConfirmedSection(),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color:
                request.type == LessonRequestType.trial
                    ? AppColors.paperDark
                    : AppColors.paperAccentSoft.withValues(alpha: 0.2),
          ),
          child: Text(
            request.type.label,
            style: AppTypography.caption.copyWith(
              color:
                  request.type == LessonRequestType.trial
                      ? AppColors.ink
                      : AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (request.isReturningStudent) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
            child: Text(
              '복귀',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          _formatRelativeTime(request.createdAt),
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 학생명+악기 동적 개체명 → §7.30 #2 + bodyLarge+w600 평행 패턴 §7.104 예외.
        Text(
          '${studentName ?? '학생'} · ${request.instrument}',
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        // Goal + Experience + Preferred time
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space1,
          children: [
            _InfoChip(icon: Icons.flag_outlined, label: request.goal.label),
            _InfoChip(
              icon: Icons.bar_chart_outlined,
              label: request.experience.label,
            ),
            if (request.preferredSlots.isEmpty &&
                request.preferredDayLabel != null)
              _InfoChip(
                icon: Icons.schedule_outlined,
                label:
                    '${request.preferredDayLabel} ${request.preferredTime ?? ''}',
              ),
          ],
        ),
        // v2.0: Show 3 preferred time slots
        if (request.preferredSlots.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space2),
          ...request.preferredSlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color:
                        slot.priority == 1
                            ? AppColors.paperAccent
                            : AppColors.inkTertiary,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    '${slot.priority}순위: ${slot.displayLabel}',
                    style: AppTypography.caption.copyWith(
                      color:
                          slot.priority == 1
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                      fontWeight:
                          slot.priority == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Text(
        request.message!,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
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
              foregroundColor: AppColors.inkSecondary,
              side: BorderSide(color: AppColors.inkQuaternary),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(AppStrings.unavailable),
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
            child: Text(AppStrings.accept),
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
            Icon(Icons.swap_horiz, size: 16, color: AppColors.ink),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '시간 협상 중 (${request.currentRound}/3 라운드)',
              style: AppTypography.caption.copyWith(
                color: AppColors.ink,
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
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Text(
              latestProposal.message!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
        ],

        // Alternative slot cards
        Text(
          '대안 시간',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space1),
        ...latestProposal.slots.asMap().entries.map(
          (entry) => _AlternativeSlotCard(
            slot: entry.value,
            index: entry.key,
            onAccept:
                onAcceptAlternative != null
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
              label: Text(AppStrings.counterPropose),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.inkSecondary,
                side: BorderSide(color: AppColors.inkQuaternary),
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
              label: const Text(AppStrings.scheduleAlternativeProposal),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeConfirmedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirmed time display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(color: AppColors.paperDark),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.paperOk),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '시간 확정',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperOk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (request.preferredDayLabel != null)
                      Text(
                        '${request.preferredDayLabel} ${request.preferredTime ?? ''}'
                        ' · ${request.preferredDuration}분',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Suggested price
        if (request.suggestedPrice != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Icon(Icons.sell_outlined, size: 14, color: AppColors.inkTertiary),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '참고 가격: ${_formatPrice(request.suggestedPrice!)}원',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ],

        // Send proposal button (teacher action)
        if (onSendProposal != null) ...[
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSendProposal,
              icon: const Icon(Icons.send, size: 16),
              label: Text(
                request.type == LessonRequestType.trial
                    ? '체험레슨 예약 완료'
                    : '수강권 제안 보내기',
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      final man = price ~/ 10000;
      final remainder = price % 10000;
      if (remainder == 0) return '$man만';
      return '$man만 ${remainder.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    }
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
  }

  Widget _buildStatusBadge() {
    final (color, bgColor) = switch (request.status) {
      UnifiedRequestStatus.approved || UnifiedRequestStatus.timeConfirmed => (
        AppColors.paperOk,
        AppColors.paperDark,
      ),
      UnifiedRequestStatus.rejected => (
        AppColors.paperAccent,
        AppColors.paperAccentSoft,
      ),
      UnifiedRequestStatus.cancelled || UnifiedRequestStatus.expired => (
        AppColors.inkTertiary,
        AppColors.paperDark,
      ),
      UnifiedRequestStatus.negotiating => (AppColors.ink, AppColors.paperDark),
      _ => (AppColors.paperAccent, AppColors.paperAccentSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        request.teacherActionLabel,
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
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.paperAccent),
              const SizedBox(width: AppSpacing.space2),
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
                    color: AppColors.paperAccent,
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
        Icon(icon, size: 14, color: AppColors.inkTertiary),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}
