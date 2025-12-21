import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';

/// Screen showing booking details
class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 상세'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cancel',
                child: Text('예약 취소'),
              ),
            ],
          ),
        ],
      ),
      body: bookingAsync.when(
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('예약을 찾을 수 없습니다'));
          }
          return _buildContent(context, ref, booking);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space3),
              Text('오류가 발생했습니다', style: AppTypography.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(bookingProvider(bookingId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, LessonBooking booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          _buildStatusCard(booking),

          const SizedBox(height: AppSpacing.space6),

          // Date & Time
          _buildSection(
            '레슨 일시',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.calendar_today,
                  '날짜',
                  booking.fullFormattedDate,
                ),
                const SizedBox(height: AppSpacing.space3),
                _buildInfoRow(
                  Icons.access_time,
                  '시간',
                  booking.timeRange,
                ),
                const SizedBox(height: AppSpacing.space3),
                _buildInfoRow(
                  Icons.timer,
                  '레슨 시간',
                  '${booking.durationMinutes}분',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Student info
          _buildSection(
            '학생 정보',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.person,
                  '이름',
                  booking.studentName,
                ),
                if (booking.studentPhone != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _buildInfoRow(
                    Icons.phone,
                    '연락처',
                    booking.studentPhone!,
                  ),
                ],
                if (booking.studentEmail != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _buildInfoRow(
                    Icons.email,
                    '이메일',
                    booking.studentEmail!,
                  ),
                ],
                if (booking.lessonGoal != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _buildInfoRow(
                    Icons.flag,
                    '레슨 목표',
                    booking.lessonGoal!.label,
                  ),
                ],
                if (booking.experienceLevel != null) ...[
                  const SizedBox(height: AppSpacing.space3),
                  _buildInfoRow(
                    Icons.school,
                    '악기 경험',
                    booking.experienceLevel!.label,
                  ),
                ],
              ],
            ),
          ),

          if (booking.studentMessage != null &&
              booking.studentMessage!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildSection(
              '학생 메시지',
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Text(
                  booking.studentMessage!,
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Payment
          _buildSection(
            '수강료',
            _buildInfoRow(
              Icons.payments,
              booking.lessonType.label,
              booking.formattedFee,
            ),
          ),

          // Suggested time slots (for unavailable status)
          if (booking.hasSuggestedTimes) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildSuggestedTimesSection(context, booking),
          ],

          // Action buttons
          if (booking.canCancel) ...[
            const SizedBox(height: AppSpacing.space8),
            _buildActionButtons(context, ref, booking),
          ],

          // Retry button for unavailable/expired statuses
          if (booking.status.canRetry) ...[
            const SizedBox(height: AppSpacing.space8),
            _buildRetryButton(context, booking),
          ],

          // For trial lessons that are completed - show convert to regular
          if (booking.isTrial && booking.status == BookingStatus.completed) ...[
            const SizedBox(height: AppSpacing.space8),
            _buildConvertToRegularButton(context, booking),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(LessonBooking booking) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: booking.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: booking.status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: booking.status.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              booking.status.icon,
              color: booking.status.color,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.label,
                  style: AppTypography.headingSmall.copyWith(
                    color: booking.status.color,
                  ),
                ),
                Text(
                  _getStatusDescription(booking),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Lesson type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: booking.lessonType.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text(
              booking.lessonType.label,
              style: AppTypography.bodySmall.copyWith(
                color: booking.lessonType.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.space3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, LessonBooking booking) {
    if (booking.isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markUnavailable(context, ref, booking),
              icon: const Icon(Icons.event_busy),
              label: const Text('일정 조율'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondaryLight,
                side: BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _approveBooking(context, ref, booking),
              icon: const Icon(Icons.check),
              label: const Text('승인'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelBooking(context, ref, booking),
        icon: const Icon(Icons.cancel),
        label: const Text('예약 취소'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildSuggestedTimesSection(
      BuildContext context, LessonBooking booking) {
    return _buildSection(
      '선생님이 제안한 다른 시간',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아래 시간 중 가능한 시간이 있으면 다시 신청해주세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          ...booking.suggestedTimeSlots!.map((slot) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      '${slot.dayName} ${slot.timeRange}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context, LessonBooking booking) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton.icon(
        onPressed: () {
          // Navigate to trial lesson request with teacher pre-selected
          context.push(
            '/schedule/trial/request?teacherId=${booking.teacherId}&teacherName=${Uri.encodeComponent(booking.teacherName)}',
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('다른 시간으로 다시 신청'),
      ),
    );
  }

  Widget _buildConvertToRegularButton(
      BuildContext context, LessonBooking booking) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: FilledButton.icon(
        onPressed: () {
          context.push('/schedule/regular/register', extra: {
            'studentName': booking.studentName,
            'teacherId': booking.teacherId,
            'teacherName': booking.teacherName,
          });
        },
        icon: const Icon(Icons.upgrade),
        label: const Text('정규레슨으로 등록'),
      ),
    );
  }

  String _getStatusDescription(LessonBooking booking) {
    switch (booking.status) {
      case BookingStatus.pending:
        return '선생님의 승인을 기다리고 있습니다';
      case BookingStatus.confirmed:
        return '레슨이 확정되었습니다';
      case BookingStatus.changeRequested:
        return '일정 변경을 요청했습니다. 선생님의 승인을 기다리고 있습니다';
      case BookingStatus.completed:
        return '레슨이 완료되었습니다';
      case BookingStatus.cancelled:
        return '예약이 취소되었습니다';
      case BookingStatus.unavailable:
        return booking.unavailableMessage ?? '해당 시간 조율이 필요해요';
      case BookingStatus.expired:
        return '48시간 내에 응답이 없어 자동 만료되었어요';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    if (action == 'cancel') {
      final booking = ref.read(bookingProvider(bookingId)).value;
      if (booking != null) {
        _cancelBooking(context, ref, booking);
      }
    }
  }

  Future<void> _approveBooking(
      BuildContext context, WidgetRef ref, LessonBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 승인'),
        content: const Text('이 예약을 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingsNotifierProvider.notifier)
            .approveTrialLesson(booking.id);
        ref.invalidate(bookingProvider(bookingId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약이 승인되었습니다'),
              backgroundColor: AppColors.practiceGood,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _markUnavailable(
      BuildContext context, WidgetRef ref, LessonBooking booking) async {
    final result = await showModalBottomSheet<
        ({UnavailableReason reason, List<TimeSlot> suggestedSlots})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UnavailableBottomSheet(
        teacherId: booking.teacherId,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref.read(bookingsNotifierProvider.notifier).markUnavailable(
              booking.id,
              result.reason,
              suggestedTimeSlots:
                  result.suggestedSlots.isNotEmpty ? result.suggestedSlots : null,
            );
        ref.invalidate(bookingProvider(bookingId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.suggestedSlots.isNotEmpty
                  ? '대안 시간과 함께 학생에게 안내가 전달되었습니다'
                  : '학생에게 안내가 전달되었습니다'),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelBooking(
      BuildContext context, WidgetRef ref, LessonBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('이 예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(bookingsNotifierProvider.notifier)
            .cancelBooking(booking.id, null);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약이 취소되었습니다'),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Bottom sheet for marking booking as unavailable with optional time suggestions
class _UnavailableBottomSheet extends ConsumerStatefulWidget {
  final String teacherId;

  const _UnavailableBottomSheet({required this.teacherId});

  @override
  ConsumerState<_UnavailableBottomSheet> createState() =>
      _UnavailableBottomSheetState();
}

class _UnavailableBottomSheetState
    extends ConsumerState<_UnavailableBottomSheet> {
  UnavailableReason? _selectedReason;
  final Set<TimeSlot> _selectedSlots = {};
  bool _showTimeSelection = false;

  @override
  Widget build(BuildContext context) {
    final availabilityAsync =
        ref.watch(teacherAvailabilityProvider(widget.teacherId));

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.screenPadding,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                AppSpacing.screenPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '일정 조율 안내',
                    style: AppTypography.headingMedium,
                  ),
                  if (_showTimeSelection)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showTimeSelection = false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('이전'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),

              if (!_showTimeSelection) ...[
                // Step 1: Select reason
                Text(
                  '학생에게 전달할 사유를 선택해주세요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                ...UnavailableReason.values.map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedReason = reason;
                            _showTimeSelection = true;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          side: BorderSide(
                            color: _selectedReason == reason
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: _selectedReason == reason ? 2 : 1,
                          ),
                        ),
                        tileColor: _selectedReason == reason
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                        leading: Icon(
                          Icons.schedule,
                          color: _selectedReason == reason
                              ? AppColors.primary
                              : AppColors.textSecondaryLight,
                        ),
                        title: Text(reason.label),
                        subtitle: Text(
                          reason.studentMessage,
                          style: AppTypography.caption,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    )),
              ] else ...[
                // Step 2: Select alternative times
                Text(
                  '대안 시간을 제안해주세요 (선택)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '대안 시간을 제안하면 학생이 더 쉽게 다른 시간을 선택할 수 있어요',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                // Available time slots
                availabilityAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return _buildNoSlotsMessage();
                    }
                    return _buildTimeSlotGrid(slots);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildNoSlotsMessage(),
                ),

                const SizedBox(height: AppSpacing.space3),

                // Manual time input button
                OutlinedButton.icon(
                  onPressed: _showManualTimeInputDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('직접 시간 추가'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Selected slots display
                if (_selectedSlots.isNotEmpty) ...[
                  Text(
                    '선택된 대안 시간 (${_selectedSlots.length}개)',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: _selectedSlots.map((slot) {
                      return Chip(
                        label: Text(slot.displayLabel),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selectedSlots.remove(slot));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Submit without suggestions
                          Navigator.pop(context, (
                            reason: _selectedReason!,
                            suggestedSlots: <TimeSlot>[],
                          ));
                        },
                        child: const Text('대안 없이 전송'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: FilledButton(
                        onPressed: _selectedSlots.isNotEmpty
                            ? () {
                                Navigator.pop(context, (
                                  reason: _selectedReason!,
                                  suggestedSlots: _selectedSlots.toList(),
                                ));
                              }
                            : null,
                        child: Text(_selectedSlots.isNotEmpty
                            ? '대안과 함께 전송'
                            : '시간을 선택하세요'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.space4),
              if (!_showTimeSelection)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSlotsMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 32, color: AppColors.textTertiaryLight),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '등록된 가용 시간이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '프로필 > 레슨 시간 설정에서 가용 시간을 등록하세요',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<TimeSlot> slots) {
    // Group slots by day
    final slotsByDay = <int, List<TimeSlot>>{};
    for (final slot in slots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    final days = slotsByDay.keys.toList()..sort();

    return Column(
      children: days.map((day) {
        final daySlots = slotsByDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              daySlots.first.fullDayName,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: daySlots.map((slot) {
                final isSelected = _selectedSlots.contains(slot);
                return FilterChip(
                  label: Text(slot.timeRange),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSlots.add(slot);
                      } else {
                        _selectedSlots.remove(slot);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _showManualTimeInputDialog() async {
    // Step 1: Select date
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (selectedDate == null || !mounted) return;

    // Step 2: Select start time
    final startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      helpText: '시작 시간',
      cancelText: '취소',
      confirmText: '다음',
    );

    if (startTime == null || !mounted) return;

    // Step 3: Select end time
    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
      helpText: '종료 시간',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (endTime == null || !mounted) return;

    // Validate end time is after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Create custom time slot
    final customSlot = TimeSlot(
      id: 'custom_${selectedDate.toIso8601String()}_${startTime.hour}',
      dayOfWeek: selectedDate.weekday,
      startTime: startTime,
      endTime: endTime,
      isActive: true,
      specificDate: selectedDate,
    );

    setState(() {
      _selectedSlots.add(customSlot);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_formatDate(selectedDate)} ${customSlot.timeRange} 추가됨',
          ),
          backgroundColor: AppColors.practiceGood,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}/${date.day}(${weekdays[date.weekday]})';
  }
}
