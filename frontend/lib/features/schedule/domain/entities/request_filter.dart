import 'unified_lesson_request.dart';

/// Sort options for lesson request lists.
enum RequestSortBy {
  createdAtDesc,
  studentNameAsc,
}

/// Preset date range options for the filter UI.
enum RequestFilterPreset {
  oneWeek,
  oneMonth,
  threeMonths,
  custom,
}

/// Filter + sort + pagination for lesson request lists.
///
/// Immutable value object — create new instances for each filter change.
class RequestFilter {
  final UnifiedRequestStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? specificDate;
  final RequestSortBy sortBy;
  final int pageSize;
  final int page;

  const RequestFilter({
    this.status,
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
      startDate: DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days)),
      endDate: today,
    );
  }

  /// Apply filter, sort, and pagination to a list of requests.
  List<UnifiedLessonRequest> apply(List<UnifiedLessonRequest> requests) {
    var result = List<UnifiedLessonRequest>.from(requests);

    // Filter by specific date (calendar click)
    if (specificDate != null) {
      result = result.where((r) {
        final d = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        return d == specificDate;
      }).toList();
    }

    // Filter by date range
    if (startDate != null && endDate != null) {
      result = result.where((r) {
        return !r.createdAt.isBefore(startDate!) &&
            !r.createdAt.isAfter(endDate!);
      }).toList();
    }

    // Filter by status
    if (status != null) {
      result = result.where((r) => r.status == status).toList();
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
    DateTime? startDate,
    DateTime? endDate,
    DateTime? specificDate,
    RequestSortBy? sortBy,
    int? pageSize,
    int? page,
  }) {
    return RequestFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      specificDate: specificDate ?? this.specificDate,
      sortBy: sortBy ?? this.sortBy,
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
    );
  }
}
