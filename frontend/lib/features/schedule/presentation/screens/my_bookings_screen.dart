import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/presentation/extensions/clock_time_ui_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/availability_slot.dart';
import '../providers/teacher_availability_providers.dart';
import 'booking_cancel_screen.dart';
import 'booking_reschedule_screen.dart';
import 'lesson_booking_screen.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../subscription/subscription_facade.dart'
    show activeSubscriptionBetweenProvider;

/// Route-level resolver for [MyBookingsScreen].
///
/// 변경/취소 진입점들이 변경권 수·subscriptionId 를 하드코딩(가짜 0/0·2/2)으로
/// 넘겨 버튼이 죽거나(#522) remote 쓰기가 빈 값으로 실패하던 문제를, 학생의 활성
/// 수강권(SSOT)에서 직접 파생해 차단한다. teacherId 가 빈 보조 진입점(#521)은
/// 후속 작업에서 자신의 teacherId 를 전달하도록 한다.
class MyBookingsRoute extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String? instrument;

  const MyBookingsRoute({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    this.instrument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 학생 본인 화면 — studentId 가 비면 현재 로그인 사용자 (route_params 폴백 원칙).
    final resolvedStudentId = studentId.isNotEmpty
        ? studentId
        : ref.watch(currentUserIdProvider);

    // teacherId 가 없으면 정확한 수강권을 특정할 수 없어 변경권 0 (버튼 비활성).
    if (teacherId.isEmpty) {
      return _screen(resolvedStudentId, remaining: 0, total: 0, subId: null,
          deadlineHours: 12);
    }

    final subAsync = ref.watch(
      activeSubscriptionBetweenProvider(
        studentId: resolvedStudentId,
        teacherId: teacherId,
      ),
    );

    return subAsync.when(
      data: (sub) => _screen(
        resolvedStudentId,
        remaining: sub?.remainingReschedule ?? 0,
        total: sub?.effectiveRescheduleAllowance ?? 0,
        subId: sub?.id,
        deadlineHours: sub?.effectiveCancelDeadlineHours ?? 12,
      ),
      loading: () => const NotebookScreenScaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) =>
          _screen(resolvedStudentId, remaining: 0, total: 0, subId: null,
          deadlineHours: 12),
    );
  }

  Widget _screen(
    String resolvedStudentId, {
    required int remaining,
    required int total,
    required String? subId,
    required int deadlineHours,
  }) {
    return MyBookingsScreen(
      studentId: resolvedStudentId,
      studentName: studentName,
      teacherId: teacherId,
      teacherName: teacherName,
      remainingReschedules: remaining,
      totalReschedules: total,
      instrument: instrument,
      subscriptionId: subId,
      cancelDeadlineHours: deadlineHours,
    );
  }
}

/// My bookings screen
///
/// Shows list of student's bookings with options to reschedule or cancel.
class MyBookingsScreen extends ConsumerWidget {
  final String studentId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final int remainingReschedules;
  final int totalReschedules;
  final String? instrument;
  final String? subscriptionId; // 🆕 For reschedule count deduction

  /// 무료-취소 마감(레슨 전 N시간). 수강권에서 파생, 미지정 12h.
  final int cancelDeadlineHours;

  const MyBookingsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.remainingReschedules,
    required this.totalReschedules,
    this.instrument,
    this.subscriptionId,
    this.cancelDeadlineHours = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get upcoming bookings (next 60 days)
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 60));

    final slotsAsync = ref.watch(
      availableSlotsForDateRangeProvider(
        teacherId: teacherId,
        startDate: now,
        endDate: endDate,
        currentStudentId: studentId,
      ),
    );

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: NotebookDetailAppBar(
        title: AppStrings.myBookingsTitle,
        // 학생 선착순 직접 예약 진입 (#580). navigation/utility 아이콘 — Material 허용.
        customActions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.ink),
            tooltip: AppStrings.bookAction,
            onPressed: () => _openDirectBooking(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Subscription info header
            _buildSubscriptionHeader(context),

            // Booking list
            Expanded(
              child: slotsAsync.when(
                data: (slots) {
                  final myBookings =
                      slots
                          .where(
                            (s) => s.status == AvailabilitySlotStatus.myBooking,
                          )
                          .toList();

                  if (myBookings.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildBookingList(context, ref, myBookings);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.paperAccent,
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            AppStrings.cannotLoadData,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionHeader(BuildContext context) {
    final canReschedule = remainingReschedules > 0;
    final isLastChance = remainingReschedules == 1;

    // Notebook × Score: 둥근 카드 + 채운 아이콘 배경 제거 → 하단 1px 잉크 라인만
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space4,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: AppColors.paperAccent, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teacherName${instrument != null ? ' · $instrument' : ''}',
                  style: NotebookTypography.pieceTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Row(
                  children: [
                    Icon(
                      canReschedule
                          ? (isLastChance
                              ? Icons.warning_amber
                              : Icons.swap_horiz)
                          : Icons.block,
                      size: 14,
                      color:
                          canReschedule
                              ? (isLastChance
                                  ? AppColors.paperAccent
                                  : AppColors.ink)
                              : AppColors.paperAccent,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      AppStrings.rescheduleUsageInline(
                        remainingReschedules,
                        totalReschedules,
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            canReschedule
                                ? (isLastChance
                                    ? AppColors.paperAccent
                                    : AppColors.inkSecondary)
                                : AppColors.paperAccent,
                        fontWeight:
                            isLastChance ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyStateWidget(
            icon: Icons.event_available,
            title: AppStrings.noBookings,
            subtitle: AppStrings.bookNewLesson,
          ),
          const SizedBox(height: AppSpacing.space4),
          FilledButton(
            onPressed: () => _openDirectBooking(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeight),
              backgroundColor: AppColors.paperAccent,
            ),
            child: Text(
              AppStrings.bookAction,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open the first-come direct booking screen (#580).
  void _openDirectBooking(BuildContext context) {
    context.push(
      AppRoutes.lessonDirectBooking,
      extra: LessonBookingParams(
        teacherId: teacherId,
        teacherName: teacherName,
        studentId: studentId,
        studentName: studentName,
        instrument: instrument,
        subscriptionId: subscriptionId,
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    WidgetRef ref,
    List<AvailabilitySlot> bookings,
  ) {
    // Sort by date
    final sortedBookings = List<AvailabilitySlot>.from(bookings)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    // Notebook × Score: ListView.builder + 하단 1px 잉크 라인으로 구분 (갭 0)
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        final booking = sortedBookings[index];
        return _buildBookingCard(context, ref, booking);
      },
    );
  }

  /// Notebook × Score booking card
  /// - 좌측 3px 세로선: 완료=paperOk / 예정=ink
  /// - 하단 1px 잉크 라인 = 다음 예약과 구분
  /// - 둥근 모서리 · 색 배경 · 그림자 제거
  Widget _buildBookingCard(
    BuildContext context,
    WidgetRef ref,
    AvailabilitySlot booking,
  ) {
    final canReschedule = remainingReschedules > 0;
    final isPast = booking.startDateTime.isBefore(DateTime.now());
    final leftColor = isPast ? AppColors.paperOk : AppColors.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: leftColor, width: 3),
          bottom: const BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Time row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Plex Mono 시간 — 악보 템포 라벨 은유
                Text(
                  '${booking.formattedStartTime}–${booking.formattedEndTime}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPast ? AppColors.inkSecondary : AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                // 날짜 — Playfair pieceTitle
                Expanded(
                  child: Text(
                    booking.formattedDate,
                    style: NotebookTypography.pieceTitle.copyWith(
                      fontSize: 15,
                      color: isPast ? AppColors.inkSecondary : AppColors.ink,
                    ),
                  ),
                ),
                if (isPast)
                  Text(
                    AppStrings.statusCompleted,
                    style: NotebookTypography.sectionLabel.copyWith(
                      color: AppColors.paperOk,
                    ),
                  ),
              ],
            ),

            if (!isPast) ...[
              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          canReschedule
                              ? () => _navigateToReschedule(context, booking)
                              : null,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text(AppStrings.rescheduleShort),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.paperAccent,
                        side: BorderSide(
                          color:
                              canReschedule
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          canReschedule
                              ? () => _navigateToCancel(context, booking)
                              : null,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(AppStrings.cancel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.paperAccent,
                        side: BorderSide(
                          color:
                              canReschedule
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!canReschedule) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.rescheduleQuotaUsedUp,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToReschedule(BuildContext context, AvailabilitySlot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingRescheduleScreen(
              teacherId: teacherId,
              teacherName: teacherName,
              studentId: studentId,
              studentName: studentName,
              currentBookingId: booking.id,
              currentDate: booking.date,
              currentStartTime: booking.startTime.toFlutterTimeOfDay(),
              remainingReschedules: remainingReschedules,
              totalReschedules: totalReschedules,
              instrument: instrument,
              subscriptionId:
                  subscriptionId, // 🆕 For reschedule count deduction
            ),
      ),
    );
  }

  void _navigateToCancel(BuildContext context, AvailabilitySlot booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookingCancelScreen(
              bookingId: booking.id,
              teacherName: teacherName,
              teacherId: teacherId,
              bookingDate: booking.date,
              startTime: booking.startTime.toFlutterTimeOfDay(),
              remainingReschedules: remainingReschedules,
              totalReschedules: totalReschedules,
              instrument: instrument,
              subscriptionId: subscriptionId,
              studentId: studentId,
              cancelDeadlineHours: cancelDeadlineHours,
            ),
      ),
    );
  }
}
