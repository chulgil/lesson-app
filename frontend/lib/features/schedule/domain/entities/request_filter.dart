import 'unified_lesson_request.dart';

/// Sort options for lesson request lists.
enum RequestSortBy { createdAtDesc, studentNameAsc }

/// Preset date range options for the filter UI.
enum RequestFilterPreset { oneWeek, oneMonth, threeMonths, custom }

/// Source filter: academy or individual.
enum RequestSourceFilter { all, academy, individual }

/// Status group for filter UI (color-based grouping).
/// 외부에서 statusGroup 필드를 세팅하는 UI가 아직 없으나, apply()에 분기 로직이
/// 있어 필터 UI 구현 시 바로 활용 가능. 제거 금지.
// ignore: unused-enum
enum RequestStatusGroup {
  all,
  active, // pending, approved, negotiating, timeConfirmed — normal color
  success, // completed, proposalAccepted, paymentNotified — green
  warning, // cancelled, expired, rejected — orange/red
}

/// Filter + sort + pagination for lesson request lists.
///
/// Immutable value object — create new instances for each filter change.
class RequestFilter {
  final UnifiedRequestStatus? status;
  final RequestStatusGroup statusGroup;
  final RequestSourceFilter source;
  final RequestPhase? phase;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? specificDate;
  final RequestSortBy sortBy;
  final int pageSize;
  final int page;

  const RequestFilter({
    this.status,
    this.statusGroup = RequestStatusGroup.all,
    this.source = RequestSourceFilter.all,
    this.phase,
    this.startDate,
    this.endDate,
    this.specificDate,
    this.sortBy = RequestSortBy.createdAtDesc,
    this.pageSize = 20,
    this.page = 0,
  });

  /// Create a filter from a preset date range.
  factory RequestFilter.preset(RequestFilterPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final days = switch (preset) {
      RequestFilterPreset.oneWeek => 7,
      RequestFilterPreset.oneMonth => 30,
      RequestFilterPreset.threeMonths => 90,
      RequestFilterPreset.custom => 0,
    };

    if (days == 0) return const RequestFilter();

    return RequestFilter(
      startDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days)),
      endDate: today,
    );
  }

  /// Apply filter, sort, and pagination to a list of requests.
  List<UnifiedLessonRequest> apply(List<UnifiedLessonRequest> requests) {
    var result = List<UnifiedLessonRequest>.from(requests);

    // Filter by specific date (calendar click)
    if (specificDate != null) {
      result =
          result.where((r) {
            final d = DateTime(
              r.createdAt.year,
              r.createdAt.month,
              r.createdAt.day,
            );
            return d == specificDate;
          }).toList();
    }

    // Filter by date range
    if (startDate != null && endDate != null) {
      result =
          result.where((r) {
            return !r.createdAt.isBefore(startDate!) &&
                !r.createdAt.isAfter(endDate!);
          }).toList();
    }

    // Filter by source (academy/individual)
    switch (source) {
      case RequestSourceFilter.academy:
        result = result.where((r) => r.isAcademy).toList();
      case RequestSourceFilter.individual:
        result = result.where((r) => !r.isAcademy).toList();
      case RequestSourceFilter.all:
        break;
    }

    // Filter by phase
    if (phase != null) {
      result = result.where((r) => r.currentPhase == phase).toList();
    }

    // Filter by status
    if (status != null) {
      result = result.where((r) => r.status == status).toList();
    }

    // Filter by status group
    switch (statusGroup) {
      case RequestStatusGroup.active:
        result = result.where((r) => r.status.isActive).toList();
      case RequestStatusGroup.success:
        result =
            result
                .where(
                  (r) => [
                    UnifiedRequestStatus.completed,
                    UnifiedRequestStatus.proposalAccepted,
                    UnifiedRequestStatus.paymentNotified,
                  ].contains(r.status),
                )
                .toList();
      case RequestStatusGroup.warning:
        result =
            result
                .where(
                  (r) => [
                    UnifiedRequestStatus.cancelled,
                    UnifiedRequestStatus.expired,
                    UnifiedRequestStatus.rejected,
                  ].contains(r.status),
                )
                .toList();
      case RequestStatusGroup.all:
        break;
    }

    // Sort
    switch (sortBy) {
      case RequestSortBy.createdAtDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case RequestSortBy.studentNameAsc:
        result.sort((a, b) => a.studentId.compareTo(b.studentId));
    }

    // Pagination
    final start = page * pageSize;
    if (start >= result.length) return [];
    final end = (start + pageSize).clamp(0, result.length);
    return result.sublist(start, end);
  }

  RequestFilter copyWith({
    UnifiedRequestStatus? status,
    RequestStatusGroup? statusGroup,
    RequestSourceFilter? source,
    RequestPhase? phase,
    bool clearPhase = false,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? specificDate,
    RequestSortBy? sortBy,
    int? pageSize,
    int? page,
  }) {
    return RequestFilter(
      status: status ?? this.status,
      statusGroup: statusGroup ?? this.statusGroup,
      source: source ?? this.source,
      phase: clearPhase ? null : (phase ?? this.phase),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      specificDate: specificDate ?? this.specificDate,
      sortBy: sortBy ?? this.sortBy,
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
    );
  }
}
