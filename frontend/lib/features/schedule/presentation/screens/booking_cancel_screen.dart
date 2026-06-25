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
import '../../domain/entities/cancel_reason.dart';
import '../../domain/services/cancellation_credit_policy.dart';
import '../providers/teacher_availability_providers.dart';
import '../widgets/teacher_cancel_policy_banner.dart';

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

  /// Free-cancel deadline window (hours before lesson). Spec §3.3.
  final int cancelDeadlineHours;

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
    this.cancelDeadlineHours = 12,
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
    final outcome = _computeOutcome();
    final canCancel = !outcome.blocked;

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
              if (!widget.isTeacherCancel) _buildCancelWarning(outcome),

              // Teacher cancel info
              if (widget.isTeacherCancel) _buildTeacherCancelInfo(),

              // 12h policy banner (G16) — only on teacher cancel within 12h
              if (widget.isTeacherCancel) ...[
                const SizedBox(height: AppSpacing.space3),
                TeacherCancelPolicyBanner(
                  hoursUntilLesson: _hoursUntilLesson(),
                ),
              ],

              const SizedBox(height: AppSpacing.space4),

              // Reason input
              _buildReasonInput(),

              const SizedBox(height: AppSpacing.space6),

              // Action buttons
              _buildActionButtons(canCancel),
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

  Widget _buildCancelWarning(CancellationCreditOutcome outcome) {
    if (outcome.blocked) {
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

    if (outcome.beforeDeadline) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: Text(
                AppStrings.bookingCancelFreeBeforeDeadline,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      );
    }

    if (outcome.remainingAfter == 0) {
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

  Widget _buildActionButtons(bool canCancel) {
    return Column(
      children: [
        // Cancel button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                canCancel && !_isLoading
                    ? () => _handleCancel()
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

  /// Scheduled lesson start datetime (date + startTime).
  DateTime _lessonStart() => DateTime(
    widget.bookingDate.year,
    widget.bookingDate.month,
    widget.bookingDate.day,
    widget.startTime.hour,
    widget.startTime.minute,
  );

  /// Hours from now until lesson start. Negative when past.
  double _hoursUntilLesson() =>
      _lessonStart().difference(DateTime.now()).inMinutes / 60.0;

  /// Cancellation credit outcome per spec (CancellationCreditPolicy = SSOT).
  CancellationCreditOutcome _computeOutcome() =>
      const CancellationCreditPolicy().compute(
        reason: widget.isTeacherCancel
            ? CancelReason.teacherCancel
            : CancelReason.studentSchedule,
        lessonStart: _lessonStart(),
        now: DateTime.now(),
        deadlineHours: widget.cancelDeadlineHours,
        usedReschedule: widget.totalReschedules - widget.remainingReschedules,
        maxReschedule: widget.totalReschedules,
      );

  Future<void> _handleCancel() async {
    // Re-evaluate at tap time in case the lesson crossed the deadline while
    // the screen was open.
    final current = _computeOutcome();
    if (current.blocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.bookingCancelImpossible)),
        );
      }
      return;
    }

    // Confirm only when this student cancel will consume the last credit.
    if (current.creditUsed > 0 &&
        current.remainingAfter == 0 &&
        !widget.isTeacherCancel) {
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

    await _performCancel(current);
  }

  Future<void> _performCancel(CancellationCreditOutcome outcome) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(slotBookingNotifierProvider.notifier);
      await notifier.cancelBooking(widget.bookingId);
      // cancelBooking swallows errors into AsyncValue.error; surface it so a
      // failed cancel never deducts a reschedule allowance or shows success.
      if (ref.read(slotBookingNotifierProvider).hasError) {
        throw Exception('booking cancel failed');
      }

      // Deduct a credit only when the policy charges this cancel (after
      // deadline, student reason). Before-deadline / teacher cancels are free.
      if (!widget.isTeacherCancel &&
          outcome.creditUsed > 0 &&
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
    // dayOfWeekLabel expects 0=Mon..6=Sun; DateTime.weekday is 1=Mon..7=Sun
    final weekday = dayOfWeekLabel(widget.bookingDate.weekday - 1);
    final hour = widget.startTime.hour.toString().padLeft(2, '0');
    final minute = widget.startTime.minute.toString().padLeft(2, '0');
    return '${widget.bookingDate.month}/${widget.bookingDate.day}($weekday) $hour:$minute';
  }
}
