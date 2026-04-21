// Group class attendance screen for teachers
// Simple "tap to toggle absence" design per UX spec

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 체크'),
        centerTitle: true,
        actions: [
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
              error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
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
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: const Center(
              child: Text('🎻', style: TextStyle(fontSize: 24)),
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
                  color: AppColors.primary,
                ),
              ),
              Text(
                '출석',
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
          Text(
            '미참석자만 탭하세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
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
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '예약된 학생이 없습니다',
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
            title: Text('로딩중...'),
          ),
      error: (e, _) => ListTile(title: const Text('오류가 발생했습니다.')),
      data: (student) {
        final studentName = student?.name ?? '알 수 없음';

        return InkWell(
          onTap: () => _toggleAttendance(booking.id),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color:
                  isAttended
                      ? Colors.transparent
                      : AppColors.paperAccent.withValues(alpha: 0.05),
              border: const Border(
                bottom: BorderSide(color: AppColors.inkQuaternary, width: 0.5),
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
                            ? AppColors.paperOk.withValues(alpha: 0.1)
                            : AppColors.paperAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isAttended ? Icons.check : Icons.close,
                      color: isAttended ? AppColors.paperOk : AppColors.paperAccent,
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
                          '미참석',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                      color: Colors.white,
                    ),
                  )
                  : const Text('수업 종료'),
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
            content: Text('출석이 저장되었습니다'),
            backgroundColor: AppColors.paperOk,
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
          (context) => AlertDialog(
            title: const Text('수업 종료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '출석: ${_getAttendedCount()}명\n'
                  '미참석: ${_attendanceState.length - _getAttendedCount()}명',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '수업을 종료하시겠습니까?\n출석한 학생의 수강권이 차감됩니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('수업 종료'),
              ),
            ],
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
            content: Text('수업이 종료되었습니다'),
            backgroundColor: AppColors.paperOk,
          ),
        );
        Navigator.of(context).pop();
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
          _isSaving = false;
        });
      }
    }
  }
}
