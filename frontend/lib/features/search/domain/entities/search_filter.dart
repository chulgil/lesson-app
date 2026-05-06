// Search domain entities - filter types and enums

/// Search scope for filtering search results
/// 검색 기능 미구현 상태에서 SearchHistoryEntry.scope 필드 타입으로 예약됨.
/// 검색 UI 구현 시 scope 필터 토글에 즉시 활용.
// ignore: unused-enum
enum SearchScope { all, teachers, students, lessons }

/// Search result type indicator
/// 검색 결과 리스트 아이템 분류용. 검색 UI 미구현 — 결과 뷰 구현 시 활용.
// ignore: unused-enum
enum SearchResultType { teacher, student, lesson, practice }

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
