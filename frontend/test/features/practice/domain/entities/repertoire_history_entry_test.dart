import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/repertoire_history_entry.dart';

void main() {
  PracticeRepertoire repertoire({
    required String id,
    DateTime? startDate,
    DateTime? endDate,
    bool isArchived = false,
    List<PracticeSection> sections = const [],
  }) {
    return PracticeRepertoire(
      id: id,
      studentId: 'student-1',
      name: 'Repertoire $id',
      startDate: startDate ?? DateTime(2026, 3, 1),
      endDate: endDate,
      isArchived: isArchived,
      sections: sections,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  PracticeSection section({
    required String id,
    bool isCompleted = false,
    List<PracticeRecording> recordings = const [],
  }) {
    return PracticeSection(
      id: id,
      repertoireId: 'rep',
      pieceName: 'piece',
      startMeasure: 1,
      endMeasure: 4,
      isCompleted: isCompleted,
      recordings: recordings,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  PracticeRecording recording(String id) => PracticeRecording(
    id: id,
    sectionId: 'section',
    filePath: '/tmp/$id',
    durationSeconds: 30,
    createdAt: DateTime(2026, 3, 1),
  );

  group('RepertoireHistoryEntry.fromRepertoire', () {
    test('archived repertoire resolves to archived status', () {
      final entry = RepertoireHistoryEntry.fromRepertoire(
        repertoire(id: 'a', isArchived: true, endDate: DateTime(2026, 5, 1)),
      );
      expect(entry.status, RepertoireHistoryStatus.archived);
      expect(entry.isOngoing, isFalse);
    });

    test(
      'completed repertoire (endDate set, not archived) maps to completed',
      () {
        final entry = RepertoireHistoryEntry.fromRepertoire(
          repertoire(
            id: 'b',
            startDate: DateTime(2026, 3, 1),
            endDate: DateTime(2026, 9, 1),
          ),
        );
        expect(entry.status, RepertoireHistoryStatus.completed);
        expect(entry.durationMonths, 6);
      },
    );

    test(
      'ongoing repertoire (no endDate, not archived) maps to inProgress',
      () {
        final entry = RepertoireHistoryEntry.fromRepertoire(
          repertoire(id: 'c', startDate: DateTime(2026, 1, 1)),
        );
        expect(entry.status, RepertoireHistoryStatus.inProgress);
        expect(entry.isOngoing, isTrue);
        expect(entry.durationMonths, 1);
      },
    );

    test('aggregates section and recording counts', () {
      final entry = RepertoireHistoryEntry.fromRepertoire(
        repertoire(
          id: 'd',
          sections: [
            section(id: 's1', isCompleted: true, recordings: [recording('r1')]),
            section(id: 's2', recordings: [recording('r2'), recording('r3')]),
          ],
        ),
      );
      expect(entry.sectionCount, 2);
      expect(entry.recordingCount, 3);
      expect(entry.completionRate, 0.5);
    });

    test('yearMonthKey pads single-digit month', () {
      final entry = RepertoireHistoryEntry.fromRepertoire(
        repertoire(id: 'e', startDate: DateTime(2026, 3, 15)),
      );
      expect(entry.yearMonthKey, '2026-03');
    });

    test('same-month start/end yields 1-month duration (§3.4.6)', () {
      final entry = RepertoireHistoryEntry.fromRepertoire(
        repertoire(
          id: 'f',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 20),
        ),
      );
      expect(entry.durationMonths, 1);
    });

    test('equality based on id', () {
      final a = RepertoireHistoryEntry.fromRepertoire(repertoire(id: 'x'));
      final b = RepertoireHistoryEntry.fromRepertoire(repertoire(id: 'x'));
      final c = RepertoireHistoryEntry.fromRepertoire(repertoire(id: 'y'));
      expect(a, b);
      expect(a, isNot(c));
    });
  });
}
