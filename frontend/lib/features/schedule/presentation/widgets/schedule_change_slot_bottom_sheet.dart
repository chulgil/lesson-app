import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/booking/entities/time_slot.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/chapter_guide_box.dart';
import '../../../lessons/domain/entities/lesson.dart';
import '../providers/week_lessons_provider.dart';
import 'alternative_time_grid.dart';

/// Result from the schedule change slot selection bottom sheet.
typedef ScheduleChangeSlotResult = ({String message, List<TimeSlot> slots});

/// Parameters for showing the schedule change slot bottom sheet.
class ScheduleChangeSlotParams {
  final String teacherId;
  final String studentId;
  final int durationMinutes;
  final String currentScheduleLabel;

  /// When true, selected slots represent recurring weekly schedules
  /// (e.g., "매주 일 10:00"). Accepted slot becomes the new fixed schedule.
  final bool isBulkChange;

  const ScheduleChangeSlotParams({
    required this.teacherId,
    required this.studentId,
    required this.durationMinutes,
    required this.currentScheduleLabel,
    this.isBulkChange = false,
  });
}

/// Shows the schedule change slot selection bottom sheet.
///
/// 부모 흐름이 `showScheduleChangeTypeBottomSheet` (BottomSheet) 으로 시작하므로
/// 본 화면도 BottomSheet 로 통일해 흐름 단절을 제거 (P0-1 Phase B(b)).
Future<ScheduleChangeSlotResult?> showScheduleChangeSlotBottomSheet(
  BuildContext context, {
  required ScheduleChangeSlotParams params,
}) {
  return showModalBottomSheet<ScheduleChangeSlotResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ScheduleChangeSlotBottomSheet(params: params),
  );
}

/// Bottom sheet for selecting alternative time slots.
///
/// Reuses [AlternativeTimeGrid] from the decline/counter-propose flow.
/// Shows teacher's weekly schedule and allows selecting up to 3 slots.
class _ScheduleChangeSlotBottomSheet extends ConsumerStatefulWidget {
  final ScheduleChangeSlotParams params;

  const _ScheduleChangeSlotBottomSheet({required this.params});

  @override
  ConsumerState<_ScheduleChangeSlotBottomSheet> createState() =>
      _ScheduleChangeSlotBottomSheetState();
}

class _ScheduleChangeSlotBottomSheetState
    extends ConsumerState<_ScheduleChangeSlotBottomSheet> {
  late DateTime _weekStart;
  final List<TimeSlot> _suggestedSlots = [];
  final _messageController = TextEditingController();

  ScheduleChangeSlotParams get params => widget.params;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(
      weekLessonsWithPreviewProvider((
        weekStart: _weekStart,
        teacherId: params.teacherId,
      )),
    );
    final mq = MediaQuery.of(context);

    return Container(
      // proposal_bottom_sheet 패턴 — maxHeight 으로 sheet 상한 고정.
      // FractionallySizedBox 금지 (scrim 삼킴) — Container constraints 사용.
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      decoration: const BoxDecoration(color: AppColors.paperDark),
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.space3),
              child: Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),
            ),
            const SizedBox(height: AppSpacing.space2),
            // Header — 바텀시트 제목 (§7.27 Playfair sectionTitle).
            _buildHeader(context),
            // Chapter guide — 단계 안내 (request_history_chat 와 시그니처 통일)
            _buildChapterGuide(),
            // Current schedule info
            _buildCurrentScheduleInfo(),
            // Bulk change info banner
            if (params.isBulkChange) _buildBulkChangeInfo(),
            // Week navigation
            _buildWeekNavigation(),
            // Grid — Flexible 로 남은 공간 (sheet 상한 안에서 grid 내부 스크롤 보존)
            Flexible(
              child: lessonsAsync.when(
                data: (lessons) => _buildGrid(lessons),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) =>
                        const Center(child: Text(AppStrings.cannotLoadData)),
              ),
            ),
            // Suggested slots list
            if (_suggestedSlots.isNotEmpty) _buildSuggestedSlotsList(),
            // Message + Submit
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Text(
            params.isBulkChange
                ? AppStrings.scheduleChangeRegularTitle
                : AppStrings.scheduleChangeSlotTitle,
            style: NotebookTypography.sectionTitle,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildChapterGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: ChapterGuideBox(
        title: AppStrings.scheduleChangeSlotGuideTitle,
        situation:
            params.isBulkChange
                ? AppStrings.scheduleChangeSlotGuideBulk
                : AppStrings.scheduleChangeSlotGuideSingle,
        // 사용자가 슬롯을 직접 선택하는 화면 — action variant.
        variant: ChapterGuideVariant.action,
      ),
    );
  }

  Widget _buildBulkChangeInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              AppStrings.bulkChangeSlotGuide,
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScheduleInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: AppColors.inkSecondary, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '${AppStrings.scheduleChangeCurrentSchedule}: ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(params.currentScheduleLabel, style: AppTypography.button),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                () => setState(() {
                  _weekStart = _weekStart.subtract(const Duration(days: 7));
                }),
          ),
          Text(
            '${_weekStart.month}/${_weekStart.day} - '
            '${weekEnd.month}/${weekEnd.day}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                () => setState(() {
                  _weekStart = _weekStart.add(const Duration(days: 7));
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Lesson> lessons) {
    return AlternativeTimeGrid(
      weekStart: _weekStart,
      lessons: lessons,
      suggestedSlots: _suggestedSlots,
      maxSlots: 3,
      onEmptyCellTap: _addSlotFromGrid,
    );
  }

  void _addSlotFromGrid(({DateTime date, int hour, int minute}) cellInfo) {
    if (_suggestedSlots.length >= 3) {
      showInfoSnackBar(context, AppStrings.maxSlotsReached);
      return;
    }

    final endMinute = cellInfo.minute + params.durationMinutes;
    final endHour = cellInfo.hour + endMinute ~/ 60;
    final endMin = endMinute % 60;

    final slot = TimeSlot(
      id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
      dayOfWeek: cellInfo.date.weekday % 7,
      startTime: TimeOfDay(hour: cellInfo.hour, minute: cellInfo.minute),
      endTime: TimeOfDay(hour: endHour, minute: endMin),
      isActive: true,
      specificDate: cellInfo.date,
    );

    setState(() => _suggestedSlots.add(slot));
  }

  Widget _buildSuggestedSlotsList() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.scheduleChangePropose} (${_suggestedSlots.length}/3)',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          ...List.generate(_suggestedSlots.length, (i) {
            final slot = _suggestedSlots[i];
            final circleNumbers = ['\u2776', '\u2777', '\u2778'];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space1),
              child: Row(
                children: [
                  Text(
                    circleNumbers[i],
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      params.isBulkChange
                          ? '${AppStrings.everyWeek} ${slot.displayLabel}'
                          : slot.displayLabel,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed:
                        () => setState(() => _suggestedSlots.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: AppSpacing.space3,
        top: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border(
          top: BorderSide(color: AppColors.inkQuaternary, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CurrentRequestBox 와 시각 align — bodySmall style + enabledBorder 명시
          // (RequestDetailScreen 메시지 입력과 hint/내용 글자 계열 통일).
          TextField(
            controller: _messageController,
            maxLines: 2,
            maxLength: 200,
            style: AppTypography.bodySmall,
            decoration: InputDecoration(
              hintText:
                  params.isBulkChange
                      ? AppStrings.scheduleChangeBulkDesc
                      : AppStrings.scheduleChangeSingleDesc,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _suggestedSlots.isEmpty ? null : _submit,
              child: Text(AppStrings.scheduleChangePropose),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final result = (
      message: _messageController.text.trim(),
      slots: List<TimeSlot>.from(_suggestedSlots),
    );
    Navigator.pop(context, result);
  }
}
