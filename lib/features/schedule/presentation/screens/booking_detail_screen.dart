import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/booking/booking_providers.dart';
import '../widgets/unavailable_bottom_sheet.dart';

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
      builder: (context) => UnavailableBottomSheet(
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
