import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../core/booking/entities/lesson_booking.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../schedule/schedule_ui_facade.dart';
import '../../../students/students_facade.dart';
import '../providers/student_home_booking_provider.dart';
import '../providers/student_lessons_tab_state_provider.dart';
import '../widgets/student_group_class_card.dart';
import '../widgets/student_lesson_card.dart';
import '../widgets/trial_booking_card.dart';
import '../../../../core/widgets/compact_week_strip.dart';

/// Student lessons tab with WeekCalendar and lesson list
class StudentLessonsTab extends ConsumerWidget {
  const StudentLessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the real Student.id (GET /students/me/profile). The auth userId
    // is not a Student.id — using it 404s on remote (mock matched by luck).
    return ref
        .watch(currentStudentProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(AppStrings.cannotLoadData)),
          data: (student) => _buildBody(context, ref, student.id),
        );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    String currentStudentId,
  ) {
    final selectedDate = ref.watch(studentSelectedDateProvider);
    final sortType = ref.watch(studentLessonSortTypeProvider);
    final scheduleAsync = ref.watch(
      studentHomeLessonsScheduleProvider(currentStudentId),
    );
    final schedule = scheduleAsync.valueOrNull;

    final studentLessons = schedule?.lessons ?? <Lesson>[];
    final trialBookings = schedule?.trialBookings ?? <LessonBooking>[];
    final markedDates = schedule?.markerDates ?? <DateTime>{};

    // Filter lessons for selected date
    final dayLessons = studentLessons
        .where(
          (l) =>
              l.date.year == selectedDate.year &&
              l.date.month == selectedDate.month &&
              l.date.day == selectedDate.day,
        )
        .toList();

    // Sort lessons
    switch (sortType) {
      case LessonSortType.timeAsc:
        dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
      case LessonSortType.nameAsc:
        dayLessons.sort(
          (a, b) => (a.teacherName ?? '').compareTo(b.teacherName ?? ''),
        );
    }

    // Filter trial bookings for selected date
    final dayTrialBookings = trialBookings
        .where(
          (b) =>
              b.lessonDate.year == selectedDate.year &&
              b.lessonDate.month == selectedDate.month &&
              b.lessonDate.day == selectedDate.day,
        )
        .toList();

    // Enrolled cohort classes meeting on the selected day. Derived from the
    // repeat rule (1=Mon..7=Sun, same basis as DateTime.weekday); drop-ins carry
    // no repeat rule so they surface through their booking, not here.
    final dayGroupClasses = ref
            .watch(studentGroupClassesProvider(currentStudentId))
            .valueOrNull
            ?.where(
              (c) =>
                  c.type == GroupClassType.regular &&
                  (c.repeatDaysOfWeek ?? const <int>[]).contains(
                    selectedDate.weekday,
                  ),
            )
            .toList() ??
        const <GroupClass>[];

    final isLoading = scheduleAsync.isLoading;
    final totalCount =
        dayLessons.length + dayTrialBookings.length + dayGroupClasses.length;

    return Column(
      children: [
        // Header: title + action button
        _buildHeader(context),

        // Pending/in-negotiation lesson requests (moved from profile tab —
        // was only reachable via 프로필 > 내 레슨 요청, HARD-GATE 중복 메뉴 금지).
        _buildPendingRequestsSection(context, ref, currentStudentId),

        // Compact week strip (unified with teacher schedule)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            0,
          ),
          child: CompactWeekStrip(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(studentSelectedDateProvider.notifier).state = date;
            },
            markerDates: markedDates,
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Date header with count and sort
        _buildDateHeader(ref, selectedDate, totalCount, sortType),

        const SizedBox(height: AppSpacing.space3),

        // Lesson list for selected date
        Expanded(
          child: _buildLessonList(
            context,
            dayLessons,
            dayTrialBookings,
            dayGroupClasses,
            currentStudentId,
            selectedDate,
            isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          NotebookMasthead(
            eyebrow: 'LESSON',
            meta: volNoLabel(now),
            trailing: IconButton(
              onPressed: () => context.push(AppRoutes.teacherSearch),
              icon: const Icon(Icons.add, color: AppColors.ink, size: 22),
              tooltip: AppStrings.studentHomeBookAction,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact "진행 중인 신청" section — surfaces pending/in-negotiation
  /// lesson requests at the top of the lessons tab so they never depend on
  /// AllLessonRequestsScreen's date window to stay visible. Renders nothing
  /// when there are none (no empty-state noise on top of the tab's own list).
  Widget _buildPendingRequestsSection(
    BuildContext context,
    WidgetRef ref,
    String currentStudentId,
  ) {
    final requestsAsync = ref.watch(
      studentUnifiedRequestsProvider(currentStudentId),
    );
    final studentNames = ref.watch(studentNameMapProvider);
    final teacherNames = ref.watch(teacherNameMapProvider);
    final academyNames = ref.watch(academyNameMapProvider);

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        final pending = requests.where((r) => r.status.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (pending.isEmpty) return const SizedBox.shrink();

        final displayRequests = pending.take(3).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space2,
            AppSpacing.screenPadding,
            AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotebookSectionHeader(
                label:
                    '${AppStrings.studentHomePendingRequestsTitle} · ${pending.length}',
                trailing: TextButton(
                  onPressed: () => context.push(
                    '${AppRoutes.myLessonRequests}?studentId=$currentStudentId',
                  ),
                  child: Text(
                    AppStrings.studentViewAll,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.inkQuaternary),
                    bottom: BorderSide(color: AppColors.inkQuaternary),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < displayRequests.length; i++) ...[
                      if (i > 0) const ThinRule(),
                      RequestListItem(
                        request: displayRequests[i],
                        studentName:
                            displayRequests[i].studentName ??
                            studentNames[currentStudentId] ??
                            AppStrings.student,
                        teacherName:
                            displayRequests[i].teacherName ??
                            teacherNames[displayRequests[i].teacherId],
                        academyName:
                            displayRequests[i].academyName ??
                            academyNames[displayRequests[i].academyId],
                        viewerRole: 'student',
                        onTap: () => context.push(
                          AppRoutes.requestDetail.replaceFirst(
                            ':id',
                            displayRequests[i].id,
                          ),
                          extra: {'viewerRole': 'student'},
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(
    WidgetRef ref,
    DateTime selectedDate,
    int totalCount,
    LessonSortType sortType,
  ) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            formatDateMDWithDayLong(selectedDate),
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              // "오늘" = 시스템 자동 인디케이터 → Tier 4 Pretendard italic
              // (README §1.1 4계층, §7.127 Gaegu 회피).
              child: Text(
                AppStrings.todayLabel,
                style: NotebookTypography.indicatorLabel,
              ),
            ),
          ],
          const Spacer(),
          Text(
            AppStrings.studentLessonsCount(totalCount),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          _buildSortDropdown(ref, sortType),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(WidgetRef ref, LessonSortType sortType) {
    return PopupMenuButton<LessonSortType>(
      onSelected: (value) {
        ref.read(studentLessonSortTypeProvider.notifier).setSortType(value);
      },
      itemBuilder: (context) => LessonSortType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  if (type == sortType)
                    Icon(Icons.check, size: 16, color: AppColors.paperAccent)
                  else
                    const SizedBox(width: AppSpacing.space4),
                  const SizedBox(width: AppSpacing.space2),
                  Text(type.displayName),
                ],
              ),
            ),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sortType.displayName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.inkSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonList(
    BuildContext context,
    List<Lesson> dayLessons,
    List<LessonBooking> dayTrialBookings,
    List<GroupClass> dayGroupClasses,
    String currentStudentId,
    DateTime selectedDate,
    bool isLoading,
  ) {
    final hasContent =
        dayLessons.isNotEmpty ||
        dayTrialBookings.isNotEmpty ||
        dayGroupClasses.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      children: [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: CircularProgressIndicator(),
            ),
          ),

        // Trial bookings
        if (dayTrialBookings.isNotEmpty) ...[
          ...dayTrialBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: TrialBookingCard(booking: booking),
            ),
          ),
        ],

        // Regular lessons
        if (dayLessons.isNotEmpty) ...[
          ...dayLessons.map((lesson) => StudentLessonCard(lesson: lesson)),
        ],

        // Enrolled cohort classes meeting today
        ...dayGroupClasses.map(
          (groupClass) => StudentGroupClassCard(
            groupClass: groupClass,
            studentId: currentStudentId,
            date: selectedDate,
          ),
        ),

        // Empty state
        if (!hasContent && !isLoading) _buildEmptyState(context),

        const SizedBox(height: AppSpacing.space6),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 240,
      child: EmptyStateWidget(
        icon: Icons.event_available,
        title: AppStrings.noUpcomingLessons,
        subtitle: AppStrings.studentHomeBookNewLesson,
        actionLabel: AppStrings.studentHomeFindTeacher,
        actionIcon: Icons.search,
        onAction: () => context.push(AppRoutes.teacherSearch),
      ),
    );
  }
}
