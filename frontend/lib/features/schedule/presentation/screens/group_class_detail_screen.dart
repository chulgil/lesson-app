// Group class detail screen for students
// Shows class info, booking status, and waitlist options

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_booking.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../providers/group_class_booking_providers.dart';

/// Screen for students to view group class details and make bookings
class GroupClassDetailScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final String studentId;
  final GroupClassSchedule schedule;
  final GroupClass groupClass;

  const GroupClassDetailScreen({
    super.key,
    required this.scheduleId,
    required this.studentId,
    required this.schedule,
    required this.groupClass,
  });

  @override
  ConsumerState<GroupClassDetailScreen> createState() =>
      _GroupClassDetailScreenState();
}

class _GroupClassDetailScreenState
    extends ConsumerState<GroupClassDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(
      studentScheduleBookingProvider(widget.scheduleId, widget.studentId),
    );
    final confirmedCountAsync = ref.watch(
      scheduleConfirmedCountProvider(widget.scheduleId),
    );
    final waitlistCountAsync = ref.watch(
      scheduleWaitlistCountProvider(widget.scheduleId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('그룹 레슨'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class info header
            _buildClassHeader(),

            const SizedBox(height: AppSpacing.space6),

            // Schedule info
            _buildScheduleInfo(),

            const SizedBox(height: AppSpacing.space6),

            // Capacity status
            confirmedCountAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('오류가 발생했습니다.'),
              data: (confirmedCount) {
                return waitlistCountAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('오류가 발생했습니다.'),
                  data: (waitlistCount) {
                    return _buildCapacityStatus(confirmedCount, waitlistCount);
                  },
                );
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Current booking status or action buttons
            bookingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('오류가 발생했습니다.'),
              data: (booking) {
                if (booking != null) {
                  return _buildCurrentBookingStatus(booking);
                }
                return confirmedCountAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (confirmedCount) {
                    return _buildActionButtons(confirmedCount);
                  },
                );
              },
            ),

            const SizedBox(height: AppSpacing.space6),

            // Class description
            if (widget.groupClass.description != null) ...[
              _buildDescription(),
              const SizedBox(height: AppSpacing.space6),
            ],

            // Policy info
            _buildPolicyInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInstrumentEmoji(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Class name
          Text(
            widget.groupClass.name,
            style: AppTypography.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.space1),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color:
                  widget.groupClass.type == GroupClassType.regular
                      ? AppColors.ink.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Text(
              widget.groupClass.type == GroupClassType.regular
                  ? '정규 클래스'
                  : '드롭인 클래스',
              style: AppTypography.caption.copyWith(
                color:
                    widget.groupClass.type == GroupClassType.regular
                        ? AppColors.ink
                        : AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: '날짜',
            value: widget.schedule.dateText,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.access_time,
            label: '시간',
            value: widget.schedule.timeText,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.timer_outlined,
            label: '수업 시간',
            value: '${widget.groupClass.durationMinutes}분',
          ),
          if (widget.groupClass.pricePerSession != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.payments_outlined,
              label: '수강료',
              value: _formatPrice(widget.groupClass.pricePerSession!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkSecondary),
        const SizedBox(width: AppSpacing.space2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCapacityStatus(int confirmedCount, int waitlistCount) {
    final isFull = confirmedCount >= widget.schedule.maxCapacity;
    final isAlmostFull =
        confirmedCount >= widget.schedule.maxCapacity - 2 && !isFull;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color:
            isFull
                ? AppColors.paperAccent.withValues(alpha: 0.05)
                : isAlmostFull
                ? AppColors.paperAccent.withValues(alpha: 0.05)
                : AppColors.paperOk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color:
              isFull
                  ? AppColors.paperAccent.withValues(alpha: 0.3)
                  : isAlmostFull
                  ? AppColors.paperAccent.withValues(alpha: 0.3)
                  : AppColors.paperOk.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Status indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color:
                      isFull
                          ? AppColors.paperAccent
                          : isAlmostFull
                          ? AppColors.paperAccent
                          : AppColors.paperOk,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                isFull
                    ? '만석'
                    : isAlmostFull
                    ? '마감임박'
                    : '예약가능',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isFull
                          ? AppColors.paperAccent
                          : isAlmostFull
                          ? AppColors.paperAccent
                          : AppColors.paperOk,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Capacity numbers
          Text(
            '$confirmedCount / ${widget.schedule.maxCapacity}명',
            style: AppTypography.headingLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          // Waitlist info
          if (isFull && waitlistCount > 0) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '대기자 현황: $waitlistCount명',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentBookingStatus(GroupClassBooking booking) {
    final isWaitlist = booking.status == GroupBookingStatus.waitlist;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color:
            isWaitlist
                ? AppColors.paperAccent.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color:
              isWaitlist
                  ? AppColors.paperAccent.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(booking.statusIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.space2),
              Text(
                booking.statusText,
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isWaitlist ? AppColors.paperAccent : AppColors.primary,
                ),
              ),
            ],
          ),

          if (isWaitlist) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '취소 발생 시 순서대로 예약됩니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _cancelBooking(booking),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.paperAccent,
                side: const BorderSide(color: AppColors.paperAccent),
              ),
              child:
                  _isProcessing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(isWaitlist ? '대기 취소' : '예약 취소'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int confirmedCount) {
    final isFull = confirmedCount >= widget.schedule.maxCapacity;
    final canWaitlist = widget.schedule.canWaitlist;

    if (isFull && !canWaitlist) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.block,
              size: 48,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '예약이 마감되었습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Main action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _createBooking,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              backgroundColor: isFull ? AppColors.paperAccent : AppColors.primary,
            ),
            child:
                _isProcessing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(isFull ? '대기자로 등록하기' : '예약하기'),
          ),
        ),

        if (isFull) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            'ℹ️ 취소 발생 시 순서대로 예약됩니다',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '클래스 소개',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            widget.groupClass.description!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.ink),
              const SizedBox(width: AppSpacing.space1),
              Text(
                '예약 안내',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '• 예약 마감: 수업 ${widget.groupClass.bookingDeadlineMinutes ~/ 60}시간 전\n'
            '• 취소 마감: 수업 ${widget.groupClass.cancelDeadlineMinutes ~/ 60}시간 전\n'
            '• 미참석 시: ${widget.groupClass.noShowPolicy == NoShowPolicy.deduct ? '수강권 차감' : '수강권 미차감'}',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getInstrumentEmoji() {
    switch (widget.groupClass.instrument?.toLowerCase()) {
      case 'violin':
      case '바이올린':
        return '🎻';
      case 'piano':
      case '피아노':
        return '🎹';
      case 'cello':
      case '첼로':
        return '🎻';
      case 'guitar':
      case '기타':
        return '🎸';
      default:
        return '🎵';
    }
  }

  String _formatPrice(int price) => price.toKoreanWon;

  Future<void> _createBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(groupClassBookingNotifierProvider.notifier);
      final booking = await notifier.createBooking(
        scheduleId: widget.scheduleId,
        studentId: widget.studentId,
      );

      if (mounted) {
        final isWaitlist = booking.status == GroupBookingStatus.waitlist;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWaitlist
                  ? '대기 ${booking.waitlistPosition}번으로 등록되었습니다'
                  : '예약이 완료되었습니다',
            ),
            backgroundColor: isWaitlist ? AppColors.paperAccent : AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _cancelBooking(GroupClassBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(booking.isOnWaitlist ? '대기 취소' : '예약 취소'),
            content: Text(
              booking.isOnWaitlist ? '대기를 취소하시겠습니까?' : '예약을 취소하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.paperAccent),
                child: const Text('취소하기'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(groupClassBookingNotifierProvider.notifier);
      await notifier.cancelBooking(booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(booking.isOnWaitlist ? '대기가 취소되었습니다' : '예약이 취소되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
