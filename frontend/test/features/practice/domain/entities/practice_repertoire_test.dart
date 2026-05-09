import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';

void main() {
  group('PracticeRepertoire.getSectionsForDate', () {
    final repositoryCreatedAt = DateTime(2026, 5, 1, 9, 0);

    PracticeSection section({
      required String id,
      required DateTime pastDate,
      required DateTime todayDate,
      required bool completedOnPast,
      required bool completedOnToday,
      DateTime? startDate,
      DateTime? endDate,
      bool isRepeat = true,
    }) {
      return PracticeSection(
        id: id,
        repertoireId: 'rep-1',
        pieceName: id,
        rangeType: SectionRangeType.measure,
        startMeasure: 1,
        endMeasure: 1,
        isCompleted: false,
        isRepeat: isRepeat,
        startDate: startDate,
        endDate: endDate,
        createdAt: repositoryCreatedAt,
        dailyStatuses: [
          if (completedOnPast)
            DailyPracticeStatus(
              id: '${id}_past',
              sectionId: id,
              date: pastDate,
              isCompleted: true,
              completedAt: DateTime(
                pastDate.year,
                pastDate.month,
                pastDate.day,
                10,
              ),
            ),
          if (completedOnToday)
            DailyPracticeStatus(
              id: '${id}_today',
              sectionId: id,
              date: todayDate,
              isCompleted: true,
              completedAt: DateTime(
                todayDate.year,
                todayDate.month,
                todayDate.day,
                10,
              ),
            ),
        ],
      );
    }

    PracticeRepertoire repertoire(List<PracticeSection> sections) {
      return PracticeRepertoire(
        id: 'rep-1',
        studentId: 'student-1',
        name: '연습 레퍼토리',
        startDate: DateTime(2026, 5, 1),
        sections: sections,
        createdAt: repositoryCreatedAt,
      );
    }

    test('returns only sections completed on past date', () {
      final today = DateTime.now();
      final pastDate = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));
      final target = repertoire([
        section(
          id: 'A',
          pastDate: pastDate,
          todayDate: DateTime(today.year, today.month, today.day),
          completedOnPast: true,
          completedOnToday: false,
        ),
        section(
          id: 'B',
          pastDate: pastDate,
          todayDate: DateTime(today.year, today.month, today.day),
          completedOnPast: false,
          completedOnToday: true,
        ),
        section(
          id: 'C',
          pastDate: pastDate,
          todayDate: DateTime(today.year, today.month, today.day),
          completedOnPast: false,
          completedOnToday: false,
        ),
      ]);

      final result = target.getSectionsForDate(
        pastDate.add(const Duration(hours: 15)),
      );

      expect(result.map((s) => s.id), ['A']);
    });

    test('returns visible sections for today regardless of historical completion', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final pastDate = todayDate.subtract(const Duration(days: 1));
      final target = repertoire([
        section(
          id: 'A',
          pastDate: pastDate,
          todayDate: todayDate,
          completedOnPast: true,
          completedOnToday: false,
        ),
        section(
          id: 'B',
          pastDate: pastDate,
          todayDate: todayDate,
          completedOnPast: false,
          completedOnToday: true,
        ),
        section(
          id: 'C',
          pastDate: pastDate,
          todayDate: todayDate,
          completedOnPast: false,
          completedOnToday: false,
        ),
      ]);

      final result = target.getSectionsForDate(todayDate.add(const Duration(hours: 8)));

      expect(result.length, 3);
      expect(
        result.map((s) => s.id).toList()..sort(),
        ['A', 'B', 'C'],
      );
    });

    test('hides sections with section-level date range outside selected past date', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final pastDate = todayDate.subtract(const Duration(days: 1));
      final target = repertoire([
        section(
          id: 'A',
          pastDate: pastDate,
          todayDate: todayDate,
          completedOnPast: true,
          completedOnToday: false,
          startDate: todayDate.subtract(const Duration(days: 3)),
          endDate: todayDate.add(const Duration(days: 3)),
        ),
        section(
          id: 'B',
          pastDate: pastDate,
          todayDate: todayDate,
          completedOnPast: true,
          completedOnToday: false,
          endDate: pastDate.subtract(const Duration(days: 1)),
        ),
      ]);

      final result = target.getSectionsForDate(pastDate.add(const Duration(hours: 13)));

      expect(result.map((s) => s.id), ['A']);
    });
  });
}
