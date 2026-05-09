import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../search/search_facade.dart';
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

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.bookingCancelTitle),
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
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.bookingToBeCancelled,
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
                  AppStrings.bookingCancelImpossible,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.rescheduleQuotaExhausted(widget.totalReschedules),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.bookingCancelContactTeacher,
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
                  AppStrings.bookingCancelLastChance,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.rescheduleUsageStatus(
                widget.totalReschedules - widget.remainingReschedules,
                widget.totalReschedules,
              ),
              style: AppTypography.bodyMedium,
            ),
            Text(
              AppStrings.rescheduleAfterCancelLast(widget.totalReschedules),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.rescheduleNoMoreAfter,
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
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.rescheduleRemaining(
                    widget.remainingReschedules,
                    widget.totalReschedules,
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.bookingCancelDeductNotice,
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
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.teacherCancelLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.teacherCancelNoStudentDeduct,
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
          AppStrings.cancelReasonOptionalLabel,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppStrings.cancelReasonInputHint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
            filled: true,
            fillColor: AppColors.paper,
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
              shape: RoundedRectangleBorder(),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.paper,
                        ),
                      ),
                    )
                    : Text(
                      AppStrings.bookingCancelAction,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.paper,
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
              shape: RoundedRectangleBorder(),
              side: const BorderSide(color: AppColors.inkQuaternary),
            ),
            child: Text(
              AppStrings.goBack,
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
                  AppStrings.contactTeacher,
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
      final confirmed = await showNotebookDialog<bool>(
        context: context,
        title: AppStrings.bookingCancelLastChanceDialogTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.rescheduleUsageStatusWithColon(
                widget.totalReschedules - widget.remainingReschedules,
                widget.totalReschedules,
              ),
              style: AppTypography.bodyMedium,
            ),
            Text(
              AppStrings.rescheduleAfterCancelMarker(widget.totalReschedules),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            const Text(AppStrings.rescheduleNoMoreAfter),
          ],
        ),
        cancelLabel: AppStrings.goBack,
        onCancel: () => Navigator.pop(context, false),
        confirmLabel: AppStrings.cancelRequestAction,
        isDestructive: true,
        onConfirm: () => Navigator.pop(context, true),
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
            content: Text(AppStrings.bookingCancelled),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.bookingCancelFailed),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.teacherInfoNotFound)),
      );
      return;
    }

    final profileAsync = ref.read(teacherFullProfileProvider(teacherId));
    final phone = profileAsync.valueOrNull?.verification.phoneNumber;

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.teacherContactNotRegistered)),
      );
      return;
    }

    _showContactBottomSheet(phone);
  }

  void _showContactBottomSheet(String phone) {
    showNotebookBottomSheet<void>(
      context: context,
      padding: EdgeInsets.zero,
      showHandle: false,
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
                    AppStrings.teacherContactTitle(widget.teacherName),
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
                          label: const Text(AppStrings.callAction),
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
                          label: const Text(AppStrings.smsAction),
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
                      label: const Text(AppStrings.copyNumber),
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
          content: Text(AppStrings.contactCopied),
          backgroundColor: AppColors.paperOk,
        ),
      );
    }
  }

  String _formatBookingDate() {
    final weekday = dayOfWeekLabel(widget.bookingDate.weekday);
    final hour = widget.startTime.hour.toString().padLeft(2, '0');
    final minute = widget.startTime.minute.toString().padLeft(2, '0');
    return '${widget.bookingDate.month}/${widget.bookingDate.day}($weekday) $hour:$minute';
  }
}
