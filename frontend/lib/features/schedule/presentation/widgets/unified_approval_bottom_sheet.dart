import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import 'weekly_calendar_picker.dart'
    show WeeklyCalendarPicker;

/// Bottom sheet for teacher to review student's 3 preferred time slots
/// and accept one, reject, or counter-propose.
///
/// v2.0: Shows student's preferredSlots as selectable cards.
/// Teacher picks one → approved, or proposes alternatives → negotiating.
class UnifiedApprovalBottomSheet extends ConsumerStatefulWidget {
  final UnifiedLessonRequest request;
  final String? studentName;
  final ScrollController scrollController;
  final VoidCallback onComplete;

  const UnifiedApprovalBottomSheet({
    super.key,
    required this.request,
    this.studentName,
    required this.scrollController,
    required this.onComplete,
  });

  @override
  ConsumerState<UnifiedApprovalBottomSheet> createState() =>
      _UnifiedApprovalBottomSheetState();
}

class _UnifiedApprovalBottomSheetState
    extends ConsumerState<UnifiedApprovalBottomSheet> {
  int? _selectedSlotIndex;
  bool _isProcessing = false;
  bool _showCounterPropose = false;
  List<PreferredTimeSlot> _counterSlots = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          const Center(child: BottomSheetHandle()),
          _buildHeader(),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                _buildStudentInfo(),
                const SizedBox(height: AppSpacing.space5),
                if (!_showCounterPropose) ...[
                  _buildPreferredSlotsSection(),
                  const SizedBox(height: AppSpacing.space4),
                  _buildRoundInfo(),
                ] else ...[
                  _buildCounterProposeSection(),
                ],
              ],
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Text(
              '${widget.request.type.label} 신청',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _getTimeSinceRequest(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    final name = widget.studentName ?? '학생';
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.headingSmall),
              Text(
                [
                  widget.request.instrument,
                  widget.request.goal.label,
                  widget.request.experience.label,
                ].join(' · '),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (widget.request.message != null &&
                  widget.request.message!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          widget.request.message!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferredSlotsSection() {
    final slots = widget.request.preferredSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '학생 희망 시간 중 하나를 선택해주세요',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (slots.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.scheduleMutedBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(
              '희망 시간이 없습니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          )
        else
          ...slots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            final isSelected = _selectedSlotIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedSlotIndex = index);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.scheduleMutedBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${slot.priority}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          slot.displayLabel,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRoundInfo() {
    final maxRounds = 2;
    final currentRound = widget.request.currentRound;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              currentRound == 0
                  ? '희망 시간 중 하나를 선택하거나, 모두 불가하면 역제안하세요'
                  : '협상 $currentRound/$maxRounds 라운드',
              style: AppTypography.caption.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterProposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.space2),
            Text(
              '역제안 — 가능한 시간을 선택해주세요',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        WeeklyCalendarPicker(
          teacherId: widget.request.teacherId,
          lessonType: widget.request.type,
          onSlotsChanged: (slots) {
            setState(() => _counterSlots = slots);
          },
        ),
        const SizedBox(height: AppSpacing.space3),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showCounterPropose = false;
              _counterSlots = [];
            });
          },
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('학생 희망 시간으로 돌아가기'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.space4,
        top: AppSpacing.space3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: _showCounterPropose
          ? _buildCounterProposeButtons()
          : _buildMainButtons(),
    );
  }

  Widget _buildMainButtons() {
    return Row(
      children: [
        // Counter-propose
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing
                ? null
                : () => setState(() => _showCounterPropose = true),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              '역제안',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        // Accept
        Expanded(
          child: FilledButton(
            onPressed:
                _selectedSlotIndex != null && !_isProcessing
                    ? _handleAccept
                    : null,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.textSecondaryLight.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '수락',
                    style:
                        AppTypography.button.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterProposeButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing
                ? null
                : () => setState(() {
                      _showCounterPropose = false;
                      _counterSlots = [];
                    }),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              '취소',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _counterSlots.isNotEmpty && !_isProcessing
                ? _handleCounterPropose
                : null,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.textSecondaryLight.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '역제안 보내기 (${_counterSlots.length}안)',
                    style:
                        AppTypography.button.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isProcessing = true);

    try {
      final actions = UnifiedLessonRequestActions(ref);
      await actions.approveRequest(
        widget.request.id,
        widget.request.teacherId,
        widget.request.studentId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('승인 처리 중 오류가 발생했습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCounterPropose() async {
    setState(() => _isProcessing = true);

    try {
      final timeSlots = _counterSlots.map((s) {
        return TimeSlotOption(
          id: 'alt_${DateTime.now().millisecondsSinceEpoch}_${s.priority}',
          dayOfWeek: s.dayOfWeek ?? 0,
          startTime: s.startTime,
          endTime: s.endTime,
        );
      }).toList();

      final actions = UnifiedLessonRequestActions(ref);
      await actions.proposeAlternatives(
        widget.request.id,
        widget.request.teacherId,
        widget.request.studentId,
        slots: timeSlots,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('역제안 전송 중 오류가 발생했습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getTimeSinceRequest() {
    final diff = DateTime.now().difference(widget.request.createdAt);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금';
  }
}
