// Repertoire timeline view model for history screen

import 'practice_repertoire.dart';

/// Monthly group timeline for repertoire history
class RepertoireTimeline {
  final List<MonthGroup> monthGroups;
  final int totalCount;
  final int completedCount;
  final int inProgressCount;

  RepertoireTimeline({required List<PracticeRepertoire> repertoires})
    : totalCount = repertoires.length,
      completedCount = repertoires.where((r) => r.endDate != null).length,
      inProgressCount = repertoires.where((r) => r.endDate == null).length,
      monthGroups = _groupByStartMonth(repertoires);

  static List<MonthGroup> _groupByStartMonth(List<PracticeRepertoire> reps) {
    final grouped = <String, List<PracticeRepertoire>>{};
    for (final rep in reps) {
      final key =
          '${rep.startDate.year}-${rep.startDate.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(rep);
    }
    return grouped.entries
        .map(
          (e) => MonthGroup(
            yearMonth: e.key,
            year: int.parse(e.key.split('-')[0]),
            month: int.parse(e.key.split('-')[1]),
            repertoires: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.yearMonth.compareTo(a.yearMonth));
  }
}

/// Month group for timeline display
class MonthGroup {
  final String yearMonth;
  final int year;
  final int month;
  final List<PracticeRepertoire> repertoires;

  const MonthGroup({
    required this.yearMonth,
    required this.year,
    required this.month,
    required this.repertoires,
  });

  /// Display label (e.g., "2025년 3월")
  String get label => '$year년 $month월';

  /// Whether this group has any in-progress repertoires
  bool get hasInProgress => repertoires.any((r) => r.endDate == null);
}
