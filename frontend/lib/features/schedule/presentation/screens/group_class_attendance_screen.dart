// Group class attendance screen for teachers
// Simple "tap to toggle absence" design per UX spec

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_booking.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../providers/group_class_booking_providers.dart';

/// Attendance screen for teachers to mark attendance
/// UX: All students default to "attended", tap to mark as absent
class GroupClassAttendanceScreen extends ConsumerStatefulWidget {
  final String scheduleId;
  final GroupClassSchedule schedule;
  final GroupClass groupClass;

  const GroupClassAttendanceScreen({
    super.key,
    required this.scheduleId,
    required this.schedule,
    required this.groupClass,
  });

  @override
  ConsumerState<GroupClassAttendanceScreen> createState() =>
      _GroupClassAttendanceScreenState();
}

class _GroupClassAttendanceScreenState
    extends ConsumerState<GroupClassAttendanceScreen> {
  // Track attendance state locally before saving
  // bookingId -> attended (true = attended, false = absent)
  final Map<String, bool> _attendanceState = {};
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(
      scheduleBookingsProvider(widget.scheduleId),
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: NotebookDetailAppBar(
        title: AppStrings.attendanceCheck,
        customActions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveAttendance,
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(AppStrings.save),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          _buildHeader(),

          // Help text
          _buildHelpText(),

          // Student list
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) =>
                      Center(child: Text('${AppStrings.errorOccurred}.')),
              data: (bookings) {
                // Filter only confirmed bookings
                final confirmedBookings =
                    bookings
                        .where(
                          (b) =>
                              b.status == GroupBookingStatus.confirmed ||
                              b.status == GroupBookingStatus.attended ||
                              b.status == GroupBookingStatus.noShow,
                        )
                        .toList();

                // Initialize attendance state (default all to attended)
                if (!_isInitialized) {
                  for (final booking in confirmedBookings) {
                    _attendanceState[booking.id] =
                        booking.status != GroupBookingStatus.noShow;
                  }
                  _isInitialized = true;
                }

                if (confirmedBookings.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildStudentList(confirmedBookings);
              },
            ),
          ),

          // Bottom action
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        children: [
          // Class icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
            child: const Center(
              child: Text('🎻', style: AppTypography.headingLarge),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Class info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupClass.name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.schedule.dateText} ${widget.schedule.timeText}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Attendance count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_getAttendedCount()}/${_attendanceState.length}',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.paperAccent,
                ),
              ),
              Text(
                AppStrings.attendedLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      color: AppColors.ink.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          // 인터랙션 힌트 = 시스템 가이드 → Tier 3 Pretendard bodyMedium
          // (README §1.1.1 결정 가이드, §7.128 자필 회피).
          Text(
            AppStrings.attendanceHint,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.inkSecondary),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.noBookedStudents,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<GroupClassBooking> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildStudentItem(booking);
      },
    );
  }

  Widget _buildStudentItem(GroupClassBooking booking) {
    final isAttended = _attendanceState[booking.id] ?? true;
    final studentAsync = ref.watch(studentProvider(booking.studentId));

    return studentAsync.when(
      loading:
          () => const ListTile(
            leading: CircularProgressIndicator(),
            title: Text(AppStrings.loadingText),
          ),
      error: (e, _) => ListTile(title: Text('${AppStrings.errorOccurred}.')),
      data: (student) {
        final studentName = student?.name ?? AppStrings.unknownName;

        return InkWell(
          onTap: () => _toggleAttendance(booking.id),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color:
                  isAttended ? Colors.transparent : AppColors.paperAccentSoft,
              border: const Border(
                bottom: BorderSide(color: AppColors.inkQuaternary, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Attendance indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isAttended
                            ? AppColors.paperOkSoft
                            : AppColors.paperAccentSoft,
                  ),
                  child: Center(
                    child: Icon(
                      isAttended ? Icons.check : Icons.close,
                      color:
                          isAttended
                              ? AppColors.paperOk
                              : AppColors.paperAccent,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          decoration:
                              isAttended ? null : TextDecoration.lineThrough,
                          color:
                              isAttended
                                  ? AppColors.ink
                                  : AppColors.inkSecondary,
                        ),
                      ),
                      if (!isAttended)
                        Text(
                          AppStrings.absentLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                    ],
                  ),
                ),

                // Tap hint
                Icon(
                  Icons.touch_app_outlined,
                  size: 20,
                  color: AppColors.inkTertiary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: const Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _finishClass,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.paper,
                    ),
                  )
                  : const Text(AppStrings.finishClass),
        ),
      ),
    );
  }

  int _getAttendedCount() {
    return _attendanceState.values.where((attended) => attended).length;
  }

  void _toggleAttendance(String bookingId) {
    setState(() {
      _attendanceState[bookingId] = !(_attendanceState[bookingId] ?? true);
      _hasChanges = true;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(groupClassBookingNotifierProvider.notifier);
      await notifier.markBatchAttendance(_attendanceState);

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.attendanceSaved),
            backgroundColor: AppColors.paperOk,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorTryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _finishClass() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => NotebookAlertDialog(
            title: AppStrings.finishClass,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.attendanceSummary(
                    _getAttendedCount(),
                    _attendanceState.length - _getAttendedCount(),
                  ),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  AppStrings.finishClassConfirm,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
            cancelLabel: AppStrings.cancel,
            onCancel: () => Navigator.pop(context, false),
            confirmLabel: AppStrings.finishClass,
            onConfirm: () => Navigator.pop(context, true),
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(groupClassBookingNotifierProvider.notifier);

      // 1. Save attendance
      await notifier.markBatchAttendance(_attendanceState);

      // 2. Deduct subscriptions for attended students
      for (final entry in _attendanceState.entries) {
        if (entry.value) {
          // Only deduct for attended
          await notifier.deductSubscription(entry.key);
        }
      }

      // 3. Auto-cancel any remaining waitlist
      await notifier.autoCancelWaitlist(widget.scheduleId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.classFinished),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorTryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
