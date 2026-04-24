import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../search/presentation/providers/teacher_search_provider.dart';
import '../../../subscription/subscription_facade.dart';
import '../providers/teacher_availability_providers.dart';

/// Booking cancellation screen
///
/// Allows students to cancel their existing booking.
/// Shows remaining reschedule count and warns when it's the last one.
class BookingCancelScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String teacherName;
  final String? teacherId;
  final DateTime bookingDate;
  final TimeOfDay startTime;
  final int remainingReschedules;
  final int totalReschedules;
  final String? instrument;
  final bool isTeacherCancel;
  final String? subscriptionId;
  final String? studentId;

  const BookingCancelScreen({
    super.key,
    required this.bookingId,
    required this.teacherName,
    this.teacherId,
    required this.bookingDate,
    required this.startTime,
    required this.remainingReschedules,
    required this.totalReschedules,
    this.instrument,
    this.isTeacherCancel = false,
    this.subscriptionId,
    this.studentId,
  });

  @override
  ConsumerState<BookingCancelScreen> createState() =>
      _BookingCancelScreenState();
}

class _BookingCancelScreenState extends ConsumerState<BookingCancelScreen> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCancel = widget.isTeacherCancel || widget.remainingReschedules > 0;
    final isLastChance =
        !widget.isTeacherCancel && widget.remainingReschedules == 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('예약 취소')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking info card
              _buildBookingInfoCard(),

              const SizedBox(height: AppSpacing.space4),

              // Warning for student cancellation
              if (!widget.isTeacherCancel)
                _buildCancelWarning(canCancel, isLastChance),

              // Teacher cancel info
              if (widget.isTeacherCancel) _buildTeacherCancelInfo(),

              const SizedBox(height: AppSpacing.space4),

              // Reason input
              _buildReasonInput(),

              const SizedBox(height: AppSpacing.space6),

              // Action buttons
              _buildActionButtons(canCancel, isLastChance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '취소할 예약',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.event_busy,
                  color: AppColors.paperAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatBookingDate(),
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${widget.teacherName}${widget.instrument != null ? ' · ${widget.instrument}' : ''}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelWarning(bool canCancel, bool isLastChance) {
    if (!canCancel) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccent.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.paperAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: AppColors.paperAccent, size: 20),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '취소 불가',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '변경/취소 횟수를 모두 사용하셨습니다 (${widget.totalReschedules}/${widget.totalReschedules}회 사용)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              '취소가 필요하시면 선생님께 직접 문의해주세요.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (isLastChance) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccent.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.paperAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: AppColors.paperAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '마지막 취소 기회',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '현재 ${widget.totalReschedules - widget.remainingReschedules}/${widget.totalReschedules}회 사용',
              style: AppTypography.bodyMedium,
            ),
            Text(
              '취소 후 ${widget.totalReschedules}/${widget.totalReschedules}회 (마지막!)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '이후 더 이상 변경/취소가 불가합니다.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '변경/취소: ${widget.remainingReschedules}/${widget.totalReschedules}회 남음',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '취소 시 1회 차감됩니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCancelInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선생님 취소',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '학생의 변경 횟수는 차감되지 않습니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '취소 사유 (선택)',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '취소 사유를 입력해주세요',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.inkQuaternary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.paperAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool canCancel, bool isLastChance) {
    return Column(
      children: [
        // Cancel button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                canCancel && !_isLoading
                    ? () => _handleCancel(isLastChance)
                    : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              shape: RoundedRectangleBorder(
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      '예약 취소하기',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Back button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              shape: RoundedRectangleBorder(
              ),
              side: const BorderSide(color: AppColors.inkQuaternary),
            ),
            child: Text(
              '돌아가기',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ),

        // Contact teacher hint
        if (!canCancel) ...[
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.paperAccent,
              ),
              const SizedBox(width: AppSpacing.space2),
              TextButton(
                onPressed: _contactTeacher,
                child: Text(
                  '선생님에게 문의하기',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _handleCancel(bool isLastChance) async {
    if (isLastChance && !widget.isTeacherCancel) {
      // Show confirmation dialog for last chance
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('마지막 취소 기회입니다'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재: ${widget.totalReschedules - widget.remainingReschedules}/${widget.totalReschedules}회 사용',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    '취소 후: ${widget.totalReschedules}/${widget.totalReschedules}회 (마지막)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  const Text('이후 더 이상 변경/취소가 불가합니다.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('돌아가기'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('취소하기'),
                ),
              ],
            ),
      );

      if (confirmed != true) return;
    }

    await _performCancel();
  }

  Future<void> _performCancel() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(slotBookingNotifierProvider.notifier)
          .cancelBooking(widget.bookingId);

      // Deduct reschedule allowance for student cancellations
      if (!widget.isTeacherCancel &&
          widget.subscriptionId != null &&
          widget.studentId != null) {
        await ref
            .read(subscriptionNotifierProvider(widget.studentId!).notifier)
            .useReschedule(widget.subscriptionId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 취소되었습니다'),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('예약 취소에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _contactTeacher() {
    final teacherId = widget.teacherId;
    if (teacherId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선생님 정보를 찾을 수 없습니다')));
      return;
    }

    final profileAsync = ref.read(teacherFullProfileProvider(teacherId));
    final phone = profileAsync.valueOrNull?.verification.phoneNumber;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선생님 연락처가 등록되지 않았습니다')));
      return;
    }

    _showContactBottomSheet(phone);
  }

  void _showContactBottomSheet(String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notebook × Score: 모달 시트 상단 제목 블록은 Playfair
                  // appBarTitle 로 통일 (§7.27). teacherName 동적 substring 허용.
                  Text(
                    '${widget.teacherName} 연락처',
                    style: NotebookTypography.appBarTitle,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    phone,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              _copyToClipboard(phone);
                            }
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('전화하기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.paperAccent,
                            side: const BorderSide(
                              color: AppColors.paperAccent,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final uri = Uri(scheme: 'sms', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              _copyToClipboard(phone);
                            }
                          },
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('문자 보내기'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.ink),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyToClipboard(phone);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('번호 복사'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _copyToClipboard(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연락처가 복사되었습니다'),
          backgroundColor: AppColors.paperOk,
        ),
      );
    }
  }

  String _formatBookingDate() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[widget.bookingDate.weekday - 1];
    final hour = widget.startTime.hour.toString().padLeft(2, '0');
    final minute = widget.startTime.minute.toString().padLeft(2, '0');
    return '${widget.bookingDate.month}/${widget.bookingDate.day}($weekday) $hour:$minute';
  }
}
