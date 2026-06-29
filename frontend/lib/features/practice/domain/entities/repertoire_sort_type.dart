import 'practice_repertoire.dart';

/// Repertoire sort type for ordering practice repertoires
enum RepertoireSortType {
  /// Created date descending (default) - newest first
  createdDesc,

  /// Created date ascending - oldest first
  createdAsc,

  /// Name ascending (alphabetical)
  nameAsc,

  /// Custom order (drag and drop)
  custom,
}

/// Extension for RepertoireSortType display
extension RepertoireSortTypeExtension on RepertoireSortType {
  /// Get icon for the sort type
  String get iconName {
    switch (this) {
      case RepertoireSortType.createdDesc:
        return 'arrow_downward';
      case RepertoireSortType.createdAsc:
        return 'arrow_upward';
      case RepertoireSortType.nameAsc:
        return 'sort_by_alpha';
      case RepertoireSortType.custom:
        return 'drag_handle';
    }
  }
}

/// Extension for sorting practice repertoires
extension RepertoireSorting on List<PracticeRepertoire> {
  /// Sort repertoires by the given sort type
  List<PracticeRepertoire> sortBy(RepertoireSortType type) {
    final sorted = List<PracticeRepertoire>.from(this);

    switch (type) {
      case RepertoireSortType.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case RepertoireSortType.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case RepertoireSortType.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case RepertoireSortType.custom:
        sorted.sort((a, b) {
          final aOrder = a.sortOrder ?? 999999;
          final bOrder = b.sortOrder ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        break;
    }

    return sorted;
  }
}
