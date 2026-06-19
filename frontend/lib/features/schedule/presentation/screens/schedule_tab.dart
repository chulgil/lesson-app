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
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../home/home_ui_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../student_home/student_home_ui_facade.dart';
import '../providers/schedule_tab_state_provider.dart';
import '../providers/schedule_view_mode_provider.dart';
import '../providers/lesson_selection_provider.dart';
import '../widgets/compact_week_strip.dart';
import '../widgets/schedule_timeline_view.dart';
import '../widgets/schedule_weekly_grid_view.dart';
import '../widgets/sticky_schedule_header_delegate.dart';

/// Calendar tab with WeekCalendar and lesson list
class ScheduleTab extends ConsumerWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(scheduleViewModeNotifierProvider);

    // §7.X / Phase A — list + weeklyGrid 은 CustomScrollView 로 헤더 collapse +
    // WeekStrip sticky 패턴 공유 (body 55% → 80% 확대). weeklyGrid 은 자체
    // ScrollController 를 제거하고 intrinsic 높이로 외부 sliver 에 위임.
    // timeline 은 자체 스크롤이 있어 Column 유지 (Phase B 예정).
    // #768 ①: 날짜 변경 시 다중선택 해제 (이전 날짜 레슨 id 가 stale).
    ref.listen(teacherSelectedDateProvider, (_, __) {
      ref.read(lessonSelectionProvider.notifier).clear();
    });
    final selectedIds = ref.watch(lessonSelectionProvider);
    final body = viewMode == ScheduleViewMode.timeline
        ? _buildPinnedLayout(context, ref, viewMode)
        : _buildCollapsibleListLayout(context, ref, viewMode);
    // 다중선택 액션바는 리스트 뷰 + 선택 항목이 있을 때만.
    final showSelectionBar =
        viewMode == ScheduleViewMode.list && selectedIds.isNotEmpty;
    return PaperScaffold(
      child: showSelectionBar
          ? Column(
              children: [
                Expanded(child: body),
                const _SelectionActionBar(),
              ],
            )
          : body,
    );
  }

  /// list + weeklyGrid 모드 — Masthead/Programme/Toggle 은 스크롤시 사라지고,
  /// CompactWeekStrip + DateHeader 는 SliverPersistentHeader 로 sticky.
  /// 본문 sliver 는 viewMode 에 따라 분기 (list = 레슨 카드, weeklyGrid = 주간 그리드).
  Widget _buildCollapsibleListLayout(
    BuildContext context,
    WidgetRef ref,
    ScheduleViewMode viewMode,
  ) {
    final selectedDate = ref.watch(teacherSelectedDateProvider);
    final sortType = ref.watch(teacherLessonSortTypeProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    return lessonsAsync.when(
      data: (lessons) {
        final dayLessons = lessons
            .where(
              (l) =>
                  l.date.year == selectedDate.year &&
                  l.date.month == selectedDate.month &&
                  l.date.day == selectedDate.day,
            )
            .toList();
        switch (sortType) {
          case LessonSortType.timeAsc:
            dayLessons.sort((a, b) => a.startTime.compareTo(b.startTime));
          case LessonSortType.nameAsc:
            dayLessons.sort((a, b) => a.studentName.compareTo(b.studentName));
        }
        final lessonDates = lessons
            .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
            .toSet();
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, ref)),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyScheduleHeaderDelegate(
                height: _stickyHeaderHeight,
                child: _buildStickyHeaderContent(
                  context: context,
                  ref: ref,
                  selectedDate: selectedDate,
                  sortType: sortType,
                  lessonCount: dayLessons.length,
                  markerDates: lessonDates,
                ),
              ),
            ),
            if (viewMode == ScheduleViewMode.weeklyGrid)
              // 주간 그리드는 자체 weekLessonsProvider 로 데이터를 가져오며,
              // intrinsic 높이로 렌더되어 외부 CustomScrollView 가 스크롤·collapse
              // 를 처리한다. 좌우 드래그로 주 단위(7일) 이동.
              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 100) return;
                    final newDate = velocity > 0
                        ? selectedDate.subtract(const Duration(days: 7))
                        : selectedDate.add(const Duration(days: 7));
                    ref.read(teacherSelectedDateProvider.notifier).state =
                        newDate;
                  },
                  child: ScheduleWeeklyGridView(selectedDate: selectedDate),
                ),
              )
            else if (dayLessons.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(scrollable: false),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                sliver: SliverList.builder(
                  itemCount: dayLessons.length,
                  itemBuilder: (context, index) =>
                      _SwipeableLessonCard(lesson: dayLessons[index]),
                ),
              ),
          ],
        );
      },
      loading: () => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, ref)),
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyScheduleHeaderDelegate(
              height: _stickyHeaderHeight,
              child: _buildStickyHeaderContent(
                context: context,
                ref: ref,
                selectedDate: selectedDate,
                sortType: sortType,
                lessonCount: 0,
                markerDates: const <DateTime>{},
              ),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (error, _) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, ref)),
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyScheduleHeaderDelegate(
              height: _stickyHeaderHeight,
              child: _buildStickyHeaderContent(
                context: context,
                ref: ref,
                selectedDate: selectedDate,
                sortType: sortType,
                lessonCount: 0,
                markerDates: const <DateTime>{},
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorState(ref, error),
          ),
        ],
      ),
    );
  }

  /// timeline/weeklyGrid 모드 — 기존 Column 레이아웃 (자체 스크롤 컨트롤러 보존).
  Widget _buildPinnedLayout(
    BuildContext context,
    WidgetRef ref,
    ScheduleViewMode viewMode,
  ) {
    final selectedDate = ref.watch(teacherSelectedDateProvider);
    final sortType = ref.watch(teacherLessonSortTypeProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    return Column(
      children: [
        _buildHeader(context, ref),
        _buildModeDateHeader(
          context: context,
          ref: ref,
          selectedDate: selectedDate,
          sortType: sortType,
          lessonsAsync: lessonsAsync,
        ),
        const SizedBox(height: AppSpacing.space2),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 100) return;
              final delta = viewMode == ScheduleViewMode.timeline
                  ? const Duration(days: 1)
                  : const Duration(days: 7);
              final newDate = velocity > 0
                  ? selectedDate.subtract(delta)
                  : selectedDate.add(delta);
              ref.read(teacherSelectedDateProvider.notifier).state = newDate;
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: viewMode == ScheduleViewMode.weeklyGrid
                  ? ScheduleWeeklyGridView(
                      key: const ValueKey(ScheduleViewMode.weeklyGrid),
                      selectedDate: selectedDate,
                    )
                  : _buildViewContent(
                      key: ValueKey(viewMode),
                      lessonsAsync: lessonsAsync,
                      selectedDate: selectedDate,
                      sortType: sortType,
                      viewMode: viewMode,
                      ref: ref,
                      context: context,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sticky 영역 내부 — CompactWeekStrip + DateHeader.
  /// 높이는 [_stickyHeaderHeight] 와 일치해야 함.
  Widget _buildStickyHeaderContent({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime selectedDate,
    required LessonSortType sortType,
    required int lessonCount,
    required Set<DateTime> markerDates,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              ref.read(teacherSelectedDateProvider.notifier).state = date;
            },
            markerDates: markerDates,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildDateHeader(ref, selectedDate, lessonCount, sortType),
        const SizedBox(height: AppSpacing.space2),
      ],
    );
  }

  /// Sticky 영역 고정 높이 — space2(8) + CompactWeekStrip(약 99)
  /// + space2(8) + DateHeader(약 29) + space2(8) ≈ 152.
  /// 위젯이 변경되면 layout test 가 회귀를 잡는다.
  static const double _stickyHeaderHeight = 152.0;

  Widget _buildViewContent({
    Key? key,
    required AsyncValue<List<Lesson>> lessonsAsync,
    required DateTime selectedDate,
    required LessonSortType sortType,
    required ScheduleViewMode viewMode,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    return lessonsAsync.when(
      data: (lessons) {
        // Filter lessons for selected date
        final dayLessons = lessons
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
            dayLessons.sort((a, b) => a.studentName.compareTo(b.studentName));
        }

        if (viewMode == ScheduleViewMode.timeline) {
          return ScheduleTimelineView(
            key: key,
            lessons: dayLessons,
            selectedDate: selectedDate,
          );
        }

        // List view (default)
        return Column(
          key: key,
          children: [
            // Date header with count and sort
            _buildDateHeader(ref, selectedDate, dayLessons.length, sortType),
            const SizedBox(height: AppSpacing.space3),
            Expanded(
              child: _buildLessonList(context, dayLessons, selectedDate),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          _buildDateHeader(ref, selectedDate, 0, sortType),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (error, _) => Column(
        children: [
          _buildDateHeader(ref, selectedDate, 0, sortType),
          Expanded(child: _buildErrorState(ref, error)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(scheduleViewModeNotifierProvider);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.space2),
          NotebookMasthead(
            eyebrow: 'SCHEDULE',
            meta: 'VOL. ${romanOf(now.month - 1)} · NO. ${now.day}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewModeToggle(
                  currentMode: viewMode,
                  onChanged: (mode) {
                    ref
                        .read(scheduleViewModeNotifierProvider.notifier)
                        .setMode(mode);
                  },
                ),
                const SizedBox(width: AppSpacing.space2),
                IconButton(
                  onPressed: () => _navigateToAddLesson(context, ref),
                  icon: const Icon(Icons.add, color: AppColors.ink, size: 22),
                  tooltip: AppStrings.addLessonTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeDateHeader({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime selectedDate,
    required LessonSortType sortType,
    required AsyncValue<List<Lesson>> lessonsAsync,
  }) {
    return lessonsAsync.when(
      data: (lessons) {
        final lessonDates = lessons
            .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
            .toSet();
        final lessonCount = lessons
            .where(
              (l) =>
                  l.date.year == selectedDate.year &&
                  l.date.month == selectedDate.month &&
                  l.date.day == selectedDate.day,
            )
            .length;
        return _buildStickyHeaderContent(
          context: context,
          ref: ref,
          selectedDate: selectedDate,
          sortType: sortType,
          lessonCount: lessonCount,
          markerDates: lessonDates,
        );
      },
      loading: () => _buildStickyHeaderContent(
        context: context,
        ref: ref,
        selectedDate: selectedDate,
        sortType: sortType,
        lessonCount: 0,
        markerDates: const <DateTime>{},
      ),
      error: (_, __) => _buildStickyHeaderContent(
        context: context,
        ref: ref,
        selectedDate: selectedDate,
        sortType: sortType,
        lessonCount: 0,
        markerDates: const <DateTime>{},
      ),
    );
  }

  Widget _buildDateHeader(
    WidgetRef ref,
    DateTime selectedDate,
    int lessonCount,
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              // Notebook × Score: 각진 뱃지 (§7.113 매트릭스 — 컨테이너 bg zero)
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
              ),
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
            AppStrings.lessonCountWithUnit(lessonCount),
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
        ref.read(teacherLessonSortTypeProvider.notifier).state = value;
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
    DateTime selectedDate,
  ) {
    if (dayLessons.isEmpty) {
      return _buildEmptyState();
    }

    // Notebook × Score: 갭 + 둥근카드 + 그림자 패턴을 제거하고, LessonCard 의
    // 하단 1px 잉크 라인이 항목 구분을 담당하도록 ListView.builder 로 전환
    // (§7.X 리스트 항목 = 악보 프로그램 행 — ThinRule 경계·paper 질감 일관).
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: dayLessons.length,
      itemBuilder: (context, index) {
        return _SwipeableLessonCard(lesson: dayLessons[index]);
      },
    );
  }

  Widget _buildEmptyState({bool scrollable = true}) {
    return EmptyStateWidget(
      icon: Icons.event_available,
      title: AppStrings.noUpcomingLessons,
      scrollable: scrollable,
    );
  }

  void _navigateToAddLesson(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.read(teacherSelectedDateProvider);
    final now = DateTime.now();
    int nextHour = now.hour + 1;
    if (nextHour > 23) nextHour = 9;

    final dateStr =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    context.push('${AppRoutes.addLesson}?date=$dateStr&hour=$nextHour');
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: AppStrings.lessonLoadFailed,
      actionLabel: AppStrings.retry,
      actionIcon: Icons.refresh,
      onAction: () => ref.invalidate(lessonsProvider),
    );
  }
}

/// Notebook × Score: 공용 `LessonCard` 를 재사용하고, 교사만 예정 레슨에 한해
/// 좌/우 스와이프로 완료/취소 액션을 노출하도록 Dismissible 로 래핑.
/// 카드 본체 디자인(좌 3px 상태선 + 하단 1px 잉크 라인)은 LessonCard 에서 관리.
class _SwipeableLessonCard extends ConsumerWidget {
  final Lesson lesson;

  const _SwipeableLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScheduled =
        lesson.displayStatus == LessonStatus.scheduled ||
        lesson.displayStatus == LessonStatus.reschedulePending;

    // #768 ①: 다중선택 — 예정 레슨만 선택 가능. long-press 로 선택 모드 진입,
    // 모드 중 탭=토글. 선택 모드에서는 스와이프를 비활성화한다.
    final selectedIds = ref.watch(lessonSelectionProvider);
    final selectionMode = selectedIds.isNotEmpty;
    final isSelected = selectedIds.contains(lesson.id);
    final selection = ref.read(lessonSelectionProvider.notifier);

    final card = LessonCard(
      lesson: lesson,
      onTap: selectionMode && isScheduled
          ? () => selection.toggle(lesson.id)
          : () => context.push(
              AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
            ),
    );

    final content = isScheduled
        ? _SelectableLessonRow(
            isSelected: isSelected,
            showIndicator: selectionMode,
            onLongPress: () => selection.toggle(lesson.id),
            child: card,
          )
        : card;

    // 비예정이거나 선택 모드 → 스와이프 없음.
    if (!isScheduled || selectionMode) return content;

    // #766: 수강권 레슨은 스와이프 취소(우→좌)를 비활성화 — plain cancelLesson 이
    // 차감 되돌림/변경권/휴강 이벤트를 우회하기 때문. 수강권 레슨 취소는 카드 탭 →
    // 상세 → 구독 취소(휴강) 플로우에서만. 완료(좌→우) 스와이프는 그대로 둔다.
    final canSwipeCancel = lesson.subscriptionId == null;

    return Dismissible(
      key: ValueKey('lesson-swipe-${lesson.id}'),
      direction: canSwipeCancel
          ? DismissDirection.horizontal // 완료(좌→우) + 취소(우→좌)
          : DismissDirection.startToEnd, // 완료만, 취소 스와이프 없음
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // #767: 완료=출석 확정 단일화 — confirmAttendance 로 라우팅해 수강권
          // 1회 차감(confirmLessonCompleted)을 발생시킨다. plain updateLesson 은
          // 차감을 누락했다. 다이얼로그가 확인을 처리하고 lessonsProvider
          // invalidate 로 카드가 갱신되므로 false 반환.
          await confirmAttendance(context, ref, lesson);
          return false;
        } else {
          return await _showConfirmDialog(
            context,
            ref,
            title: AppStrings.actionLessonCancel,
            message: AppStrings.confirmLessonCancellation(lesson.studentName),
            confirmLabel: AppStrings.cancel,
            confirmColor: AppColors.paperAccent,
            onConfirm: () async {
              await ref
                  .read(lessonsNotifierProvider.notifier)
                  .cancelLesson(lesson.id);
            },
          );
        }
      },
      // Notebook × Score: 스와이프 배경도 paper 톤 + 둥근 모서리 제거로
      // 카드 경계(좌 3px · 하단 1px)와 같은 평면 질감을 유지.
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.space5),
        color: AppColors.paperOk,
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.paper),
            SizedBox(width: AppSpacing.space2),
            Text(
              AppStrings.attendanceConfirmAction,
              style: TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space5),
        color: AppColors.paperAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              AppStrings.cancel,
              style: TextStyle(
                color: AppColors.paper,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppSpacing.space2),
            Icon(Icons.cancel, color: AppColors.paper),
          ],
        ),
      ),
      child: content,
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: title,
      content: Text(message),
      confirmLabel: confirmLabel,
      cancelLabel: AppStrings.goBack,
      confirmColor: confirmColor,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );

    if (confirmed == true) {
      await onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.lessonActionCompleted(
                lesson.studentName,
                confirmLabel,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return false;
  }
}

/// 3-segment toggle for switching between schedule view modes.
class _ViewModeToggle extends StatelessWidget {
  final ScheduleViewMode currentMode;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ViewModeToggle({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 각진 토글 + 그림자 제거 (§7.113/§7.114)
    // 종이 위 직사각 세그먼트 — 선택 시 paper 배경으로 대비만 유지
    return Container(
      decoration: const BoxDecoration(color: AppColors.scheduleMutedBackground),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ScheduleViewMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.paper : Colors.transparent,
              ),
              child: Icon(
                _getIcon(mode),
                size: 16,
                color: isSelected
                    ? AppColors.paperAccent
                    : AppColors.inkTertiary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIcon(ScheduleViewMode mode) {
    switch (mode) {
      case ScheduleViewMode.list:
        return Icons.format_list_bulleted;
      case ScheduleViewMode.timeline:
        return Icons.view_day;
      case ScheduleViewMode.weeklyGrid:
        return Icons.grid_view;
    }
  }
}


// ──────────────────────────────────────────────────────────────
// 다중선택 (#768 ①).
// ──────────────────────────────────────────────────────────────

/// 다중선택 시 카드에 체크 인디케이터 + 선택 배경을 덧입히고, long-press 로 선택을
/// 토글한다. 선택 모드가 아니면 인디케이터 없이 long-press 만 노출(모드 진입용).
class _SelectableLessonRow extends StatelessWidget {
  final bool isSelected;
  final bool showIndicator;
  final VoidCallback onLongPress;
  final Widget child;

  const _SelectableLessonRow({
    required this.isSelected,
    required this.showIndicator,
    required this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? AppColors.paperAccent.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            if (showIndicator)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.space2),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected
                      ? AppColors.paperAccent
                      : AppColors.inkTertiary,
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// 다중선택 하단 액션바 — 선택 개수 + 전체선택 + 일괄 완료/휴강.
class _SelectionActionBar extends ConsumerWidget {
  const _SelectionActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(lessonSelectionProvider);
    final selectedDate = ref.watch(teacherSelectedDateProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final selection = ref.read(lessonSelectionProvider.notifier);

    final dayScheduled = lessonsAsync.maybeWhen(
      data: (lessons) => lessons
          .where(
            (l) =>
                l.date.year == selectedDate.year &&
                l.date.month == selectedDate.month &&
                l.date.day == selectedDate.day &&
                (l.displayStatus == LessonStatus.scheduled ||
                    l.displayStatus == LessonStatus.reschedulePending),
          )
          .toList(),
      orElse: () => <Lesson>[],
    );
    final selectedLessons = dayScheduled
        .where((l) => selectedIds.contains(l.id))
        .toList();
    final count = selectedLessons.length;

    return Container(
      color: AppColors.paper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.5, color: AppColors.inkQuaternary),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space3,
                AppSpacing.space2,
                AppSpacing.space3,
                AppSpacing.space2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: AppStrings.selectionExitTooltip,
                        color: AppColors.inkSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: selection.clear,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        AppStrings.selectionCountLabel(count),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            selection.selectAll(dayScheduled.map((l) => l.id)),
                        child: const Text(AppStrings.selectAllAction),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: count == 0
                              ? null
                              : () => batchMarkDayOff(
                                  context,
                                  ref,
                                  selectedLessons,
                                  onDone: selection.clear,
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              0,
                              AppSpacing.buttonHeightSmall,
                            ),
                          ),
                          child: Text(AppStrings.batchSelectionDayOff(count)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: FilledButton(
                          onPressed: count == 0
                              ? null
                              : () => batchConfirmAttendance(
                                  context,
                                  ref,
                                  selectedLessons,
                                  onDone: selection.clear,
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(
                              0,
                              AppSpacing.buttonHeightSmall,
                            ),
                          ),
                          child: Text(AppStrings.batchSelectionComplete(count)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
