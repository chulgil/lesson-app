import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/compact_week_strip.dart';
import '../../domain/entities/request_filter.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../providers/unified_lesson_request_providers.dart';
import '../widgets/request_list_item.dart';

/// Full-screen lesson request list with calendar, filter, and pagination.
///
/// Calendar click and filter search are exclusive:
/// - Calendar click → filter resets, shows requests for that day
/// - Filter search → calendar selection clears
class AllLessonRequestsScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String viewerRole;

  const AllLessonRequestsScreen({
    super.key,
    required this.teacherId,
    this.viewerRole = 'teacher',
  });

  @override
  ConsumerState<AllLessonRequestsScreen> createState() =>
      _AllLessonRequestsScreenState();
}

class _AllLessonRequestsScreenState
    extends ConsumerState<AllLessonRequestsScreen> {
  DateTime _selectedDate = DateTime.now();
  RequestFilter _filter = RequestFilter(
    specificDate: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ),
  );
  RequestFilterPreset _selectedPreset = RequestFilterPreset.oneWeek;
  RequestStatusGroup _statusGroup = RequestStatusGroup.all;
  RequestSourceFilter _sourceFilter = RequestSourceFilter.all;
  RequestSortBy _sortBy = RequestSortBy.createdAtDesc;
  bool _isFilterMode = false;

  @override
  Widget build(BuildContext context) {
    final requestsAsync =
        widget.viewerRole == 'teacher'
            ? ref.watch(teacherUnifiedRequestsProvider(widget.teacherId))
            : ref.watch(studentUnifiedRequestsProvider(widget.teacherId));
    final studentNames = ref.watch(studentNameMapProvider);
    final academyNames = ref.watch(academyNameMapProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(AppStrings.lessonRequestTitle),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(AppStrings.requestLoadError,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondaryLight)),
        ),
        data: (allRequests) {
          final filtered = _filter.apply(allRequests);
          final requestDates = allRequests
              .map((r) => DateTime(
                  r.createdAt.year, r.createdAt.month, r.createdAt.day))
              .toSet();

          return Column(
            children: [
              // Compact week strip (unified across all screens)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space2,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: CompactWeekStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: _onCalendarDateSelected,
                  markerDates: requestDates,
                ),
              ),

              // Date label + count + sort
              _buildSubHeader(filtered.length),

              // Filter bar
              _buildFilterBar(),

              // Request list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noHistory,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textTertiaryLight),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.space3,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.space2),
                        itemBuilder: (context, index) {
                          final request = filtered[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMedium),
                              border: Border.all(
                                  color: AppColors.borderLight),
                            ),
                            child: RequestListItem(
                              request: request,
                              studentName: studentNames[request.studentId] ?? AppStrings.student,
                              academyName: academyNames[request.academyId],
                              onTap: () => context.push(
                                AppRoutes.requestDetail
                                    .replaceFirst(':id', request.id),
                                extra: {'viewerRole': widget.viewerRole},
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onCalendarDateSelected(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = date;
      _isFilterMode = false;
      _filter = RequestFilter(
        specificDate: dateOnly,
        sortBy: _sortBy,
      );
    });
  }

  Widget _buildSubHeader(int count) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final d = _selectedDate;
    final dayLabel = weekdays[d.weekday - 1];
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;

    final dateText = _isFilterMode
        ? _selectedPreset.label
        : '${d.month}월 ${d.day}일 $dayLabel요일${isToday ? ' 오늘' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Text(
        '$dateText · $count개 요청',
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: AppSpacing.space2,
      ),
      child: Column(
        children: [
          // Row 1: source + status + sort
          Wrap(
            spacing: AppSpacing.space1,
            runSpacing: AppSpacing.space1,
            children: [
              ..._buildSourceChips(),
              _buildDivider(),
              ..._buildStatusChips(),
              _buildDivider(),
              _buildSortChip(),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          // Row 2: period presets
          Row(
            children: _buildPeriodChips(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
      child: Container(
        width: 1,
        height: 20,
        color: AppColors.borderLight,
      ),
    );
  }

  Widget _buildSortChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = _sortBy == RequestSortBy.createdAtDesc
              ? RequestSortBy.studentNameAsc
              : RequestSortBy.createdAtDesc;
          _filter = _filter.copyWith(sortBy: _sortBy);
        });
      },
      child: Chip(
        avatar: Icon(
          Icons.swap_vert,
          size: 14,
          color: AppColors.textSecondaryLight,
        ),
        label: Text(
          _sortBy == RequestSortBy.createdAtDesc
              ? AppStrings.sortByTime
              : AppStrings.sortByName,
        ),
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  List<Widget> _buildSourceChips() {
    // Toggle chips: no "전체" — deselect = all
    const options = [
      (RequestSourceFilter.academy, AppStrings.academy),
      (RequestSourceFilter.individual, AppStrings.filterIndividual),
    ];

    return options.map((option) {
      final (value, label) = option;
      final selected = _sourceFilter == value;
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            // Toggle: tap again to deselect → back to all
            _sourceFilter = selected ? RequestSourceFilter.all : value;
            _filter = _filter.copyWith(source: _sourceFilter);
          });
        },
        labelStyle: AppTypography.caption.copyWith(
          color: selected ? Colors.white : AppColors.textSecondaryLight,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();
  }

  List<Widget> _buildStatusChips() {
    // Toggle chips: no "전체" — deselect = all
    const options = [
      (RequestStatusGroup.active, AppStrings.filterActive),
      (RequestStatusGroup.success, AppStrings.statusCompleted),
      (RequestStatusGroup.warning, AppStrings.statusCancelledExpired),
    ];

    return options.map((option) {
      final (value, label) = option;
      final selected = _statusGroup == value;
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _statusGroup = selected ? RequestStatusGroup.all : value;
            _filter = _filter.copyWith(statusGroup: _statusGroup);
          });
        },
        labelStyle: AppTypography.caption.copyWith(
          color: selected ? Colors.white : AppColors.textSecondaryLight,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }).toList();
  }

  List<Widget> _buildPeriodChips() {
    const options = [
      (RequestFilterPreset.oneWeek, AppStrings.periodOneWeek),
      (RequestFilterPreset.oneMonth, AppStrings.periodOneMonth),
      (RequestFilterPreset.threeMonths, AppStrings.periodThreeMonths),
    ];

    return options.map((option) {
      final (value, label) = option;
      final selected = _isFilterMode && _selectedPreset == value;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.space1),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            setState(() {
              if (selected) {
                // Toggle off → return to calendar date mode
                _isFilterMode = false;
                _filter = RequestFilter(
                  specificDate: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  ),
                  statusGroup: _statusGroup,
                  source: _sourceFilter,
                  sortBy: _sortBy,
                );
              } else {
                _selectedPreset = value;
                _isFilterMode = true;
                final presetFilter = RequestFilter.preset(value);
                _filter = presetFilter.copyWith(
                  statusGroup: _statusGroup,
                  source: _sourceFilter,
                  sortBy: _sortBy,
                );
              }
            });
          },
          labelStyle: AppTypography.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondaryLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: AppColors.surfaceLight,
          selectedColor: AppColors.info,
          side: BorderSide(
            color: selected ? AppColors.info : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }).toList();
  }
}
