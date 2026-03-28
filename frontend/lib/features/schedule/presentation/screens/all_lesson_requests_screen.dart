import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/week_calendar_widget.dart';
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

  const AllLessonRequestsScreen({super.key, required this.teacherId});

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
  UnifiedRequestStatus? _selectedStatus;
  RequestSortBy _sortBy = RequestSortBy.createdAtDesc;
  bool _isFilterMode = false;

  @override
  Widget build(BuildContext context) {
    final requestsAsync =
        ref.watch(teacherUnifiedRequestsProvider(widget.teacherId));

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
              // Calendar
              WeekCalendarWidget(
                selectedDate: _selectedDate,
                onDateSelected: _onCalendarDateSelected,
                lessonDates: requestDates,
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
                            vertical: AppSpacing.space2),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: AppSpacing.space4),
                        itemBuilder: (context, index) {
                          final request = filtered[index];
                          return RequestListItem(
                            request: request,
                            studentName: AppStrings.student,
                            lastMessage: request.lastMessage,
                            onTap: () => context.push(
                              AppRoutes.requestDetail
                                  .replaceFirst(':id', request.id),
                              extra: {'viewerRole': 'teacher'},
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
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${d.month}월 ${d.day}일 $dayLabel요일${isToday ? ' 오늘' : ''}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count개 요청',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Sort selector
          DropdownButton<RequestSortBy>(
            value: _sortBy,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            items: const [
              DropdownMenuItem(
                value: RequestSortBy.createdAtDesc,
                child: Text('시간순'),
              ),
              DropdownMenuItem(
                value: RequestSortBy.studentNameAsc,
                child: Text('이름순'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
                _filter = _filter.copyWith(sortBy: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Row(
        children: [
          // Period preset
          Expanded(
            child: DropdownButton<RequestFilterPreset>(
              value: _isFilterMode ? _selectedPreset : null,
              hint: const Text('기간 필터'),
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              items: const [
                DropdownMenuItem(
                  value: RequestFilterPreset.oneWeek,
                  child: Text('일주일'),
                ),
                DropdownMenuItem(
                  value: RequestFilterPreset.oneMonth,
                  child: Text('한달'),
                ),
                DropdownMenuItem(
                  value: RequestFilterPreset.threeMonths,
                  child: Text('세달'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedPreset = value;
                  _isFilterMode = true;
                  final presetFilter = RequestFilter.preset(value);
                  _filter = presetFilter.copyWith(
                    status: _selectedStatus,
                    sortBy: _sortBy,
                  );
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          // Status filter
          Expanded(
            child: DropdownButton<UnifiedRequestStatus?>(
              value: _selectedStatus,
              hint: const Text('상태'),
              underline: const SizedBox.shrink(),
              isDense: true,
              isExpanded: true,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('전체')),
                ...UnifiedRequestStatus.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  if (_isFilterMode) {
                    _filter = _filter.copyWith(status: value);
                  } else {
                    _filter = _filter.copyWith(status: value);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
