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

/// Full-screen lesson request list with calendar, phase tabs, and filters.
///
/// Filter hierarchy (top → bottom):
/// 1. Calendar strip — date selection
/// 2. Phase tabs — lifecycle phase (primary filter)
/// 3. Secondary filters — source, sort, period (single row)
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
  RequestSourceFilter _sourceFilter = RequestSourceFilter.all;
  RequestSortBy _sortBy = RequestSortBy.createdAtDesc;
  RequestPhase? _phaseFilter;
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
              // 1. Calendar strip
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

              // 2. Phase filter tabs (primary)
              _buildPhaseTabs(allRequests),

              // Date label + count
              _buildSubHeader(filtered.length),

              // 3. Secondary filters (single row)
              _buildSecondaryFilters(),

              // 4. Request list
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Calendar
  // ═══════════════════════════════════════════════════════════════════════════

  void _onCalendarDateSelected(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = date;
      _isFilterMode = false;
      _phaseFilter = null;
      _filter = RequestFilter(
        specificDate: dateOnly,
        sortBy: _sortBy,
      );
    });
  }

  void _onPhaseSelected(RequestPhase? phase) {
    setState(() {
      _phaseFilter = phase;
      if (phase == null) {
        // "전체" — return to calendar date mode
        _isFilterMode = false;
        _filter = RequestFilter(
          specificDate: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          ),
          source: _sourceFilter,
          sortBy: _sortBy,
        );
      } else {
        // Specific phase — clear date filter, show all matching
        _isFilterMode = false;
        _filter = RequestFilter(
          phase: phase,
          source: _sourceFilter,
          sortBy: _sortBy,
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase tabs (primary filter)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhaseTabs(List<UnifiedLessonRequest> allRequests) {
    final phaseCounts = <RequestPhase?, int>{null: allRequests.length};
    for (final r in allRequests) {
      final phase = r.currentPhase;
      phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;
    }

    final tabs = <(RequestPhase?, String)>[
      (null, AppStrings.phaseFilterAll),
      (RequestPhase.request, AppStrings.phaseFilterRequest),
      (RequestPhase.subscription, AppStrings.phaseFilterSubscription),
      (RequestPhase.lessons, AppStrings.phaseFilterInProgress),
      (RequestPhase.completed, AppStrings.phaseFilterCompleted),
      (RequestPhase.terminal, AppStrings.phaseFilterTerminal),
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: AppSpacing.space2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.space1),
        itemBuilder: (context, index) {
          final (phase, label) = tabs[index];
          final count = phaseCounts[phase] ?? 0;
          final isSelected = _phaseFilter == phase;

          return GestureDetector(
            onTap: () => _onPhaseSelected(phase),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Text(
                  count > 0 ? '$label $count' : label,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondaryLight,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sub header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubHeader(int count) {
    final String dateText;

    if (_phaseFilter != null) {
      // Phase filter active — show phase name instead of date
      const phaseLabels = {
        RequestPhase.request: AppStrings.phaseFilterRequest,
        RequestPhase.subscription: AppStrings.phaseFilterSubscription,
        RequestPhase.lessons: AppStrings.phaseFilterInProgress,
        RequestPhase.completed: AppStrings.phaseFilterCompleted,
        RequestPhase.terminal: AppStrings.phaseFilterTerminal,
      };
      dateText = phaseLabels[_phaseFilter] ?? AppStrings.phaseFilterAll;
    } else if (_isFilterMode) {
      dateText = _selectedPreset.label;
    } else {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final d = _selectedDate;
      final dayLabel = weekdays[d.weekday - 1];
      final now = DateTime.now();
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;
      dateText = '${d.month}월 ${d.day}일 $dayLabel요일${isToday ? ' 오늘' : ''}';
    }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // Secondary filters (single row: source + sort + period)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSecondaryFilters() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: AppSpacing.space2,
      ),
      child: Wrap(
        spacing: AppSpacing.space1,
        runSpacing: AppSpacing.space1,
        children: [
          // Source filters
          ..._buildSourceChips(),
          _buildDivider(),
          // Sort toggle
          _buildSortChip(),
          _buildDivider(),
          // Period presets
          ..._buildPeriodChips(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 1,
        height: 24,
        color: AppColors.borderLight,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Chip builders (unified pill style)
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildSourceChips() {
    const options = [
      (RequestSourceFilter.academy, AppStrings.academy),
      (RequestSourceFilter.individual, AppStrings.filterIndividual),
    ];

    return options.map((option) {
      final (value, label) = option;
      final selected = _sourceFilter == value;
      return _buildUnifiedChip(
        label: label,
        selected: selected,
        onTap: () {
          setState(() {
            _sourceFilter = selected ? RequestSourceFilter.all : value;
            _filter = _filter.copyWith(source: _sourceFilter);
          });
        },
      );
    }).toList();
  }

  Widget _buildSortChip() {
    return _buildUnifiedChip(
      label: _sortBy == RequestSortBy.createdAtDesc
          ? AppStrings.sortByTime
          : AppStrings.sortByName,
      selected: false,
      icon: Icons.swap_vert,
      onTap: () {
        setState(() {
          _sortBy = _sortBy == RequestSortBy.createdAtDesc
              ? RequestSortBy.studentNameAsc
              : RequestSortBy.createdAtDesc;
          _filter = _filter.copyWith(sortBy: _sortBy);
        });
      },
    );
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
      return _buildUnifiedChip(
        label: label,
        selected: selected,
        onTap: () {
          setState(() {
            if (selected) {
              _isFilterMode = false;
              _filter = RequestFilter(
                specificDate: DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                ),
                phase: _phaseFilter,
                source: _sourceFilter,
                sortBy: _sortBy,
              );
            } else {
              _selectedPreset = value;
              _isFilterMode = true;
              final presetFilter = RequestFilter.preset(value);
              _filter = presetFilter.copyWith(
                phase: _phaseFilter,
                source: _sourceFilter,
                sortBy: _sortBy,
              );
            }
          });
        },
      );
    }).toList();
  }

  /// Unified chip style — pill shape for all secondary filters.
  Widget _buildUnifiedChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected
                    ? Colors.white
                    : AppColors.textSecondaryLight,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
