// Search domain entities - filter types and enums

/// Search scope for filtering search results
enum SearchScope {
  all,
  teachers,
  students,
  lessons;

  String get label {
    switch (this) {
      case SearchScope.all:
        return '전체';
      case SearchScope.teachers:
        return '선생님';
      case SearchScope.students:
        return '학생';
      case SearchScope.lessons:
        return '레슨';
    }
  }
}

/// Search result type indicator
enum SearchResultType {
  teacher,
  student,
  lesson,
  practice;

  String get label {
    switch (this) {
      case SearchResultType.teacher:
        return '선생님';
      case SearchResultType.student:
        return '학생';
      case SearchResultType.lesson:
        return '레슨';
      case SearchResultType.practice:
        return '연습';
    }
  }
}

/// Search history entry
class SearchHistoryEntry {
  final String query;
  final SearchScope scope;
  final DateTime searchedAt;

  const SearchHistoryEntry({
    required this.query,
    required this.scope,
    required this.searchedAt,
  });
}
