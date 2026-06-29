import 'practice_repertoire.dart';

/// Section sort type for ordering practice sections
enum SectionSortType {
  /// Created date descending (default) - newest first
  createdDesc,

  /// Created date ascending - oldest first
  createdAsc,

  /// Name ascending (alphabetical)
  nameAsc,

  /// Measure number ascending (by start measure)
  measureAsc,

  /// Last practiced descending - recently practiced first
  lastPracticedDesc,

  /// Custom order (drag and drop)
  custom,
}

/// Extension for SectionSortType display
extension SectionSortTypeExtension on SectionSortType {
  /// Get icon for the sort type
  String get iconName {
    switch (this) {
      case SectionSortType.createdDesc:
        return 'arrow_downward';
      case SectionSortType.createdAsc:
        return 'arrow_upward';
      case SectionSortType.nameAsc:
        return 'sort_by_alpha';
      case SectionSortType.measureAsc:
        return 'music_note';
      case SectionSortType.lastPracticedDesc:
        return 'schedule';
      case SectionSortType.custom:
        return 'drag_handle';
    }
  }
}

/// Extension for sorting practice sections
extension SectionSorting on List<PracticeSection> {
  /// Sort sections by the given sort type
  List<PracticeSection> sortBy(SectionSortType type) {
    final sorted = List<PracticeSection>.from(this);

    switch (type) {
      case SectionSortType.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SectionSortType.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SectionSortType.nameAsc:
        sorted.sort((a, b) => a.pieceName.compareTo(b.pieceName));
        break;
      case SectionSortType.measureAsc:
        sorted.sort((a, b) => a.startMeasure.compareTo(b.startMeasure));
        break;
      case SectionSortType.lastPracticedDesc:
        sorted.sort((a, b) {
          final aTime = a.lastPracticedAt ?? DateTime(1970);
          final bTime = b.lastPracticedAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
      case SectionSortType.custom:
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
