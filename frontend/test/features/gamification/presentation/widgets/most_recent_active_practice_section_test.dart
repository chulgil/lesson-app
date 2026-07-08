import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_section.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';

/// Slice 2 — "이어서" 칩 대상 곡 선택 순수 함수 검증.
/// [mostRecentActivePracticeSection] 이 완료되지 않은 section 중
/// 가장 최근 [PracticeSection.lastPracticedAt] 을 고르는지, 연습 이력이
/// 전혀 없으면 null 을 주는지, 완료 section 을 제외하는지 확인한다.

PracticeSection _section({
  required String id,
  required String pieceName,
  DateTime? lastPracticedAt,
  bool isCompleted = false,
}) {
  return PracticeSection(
    id: id,
    repertoireId: 'r1',
    pieceName: pieceName,
    startMeasure: 1,
    endMeasure: 8,
    createdAt: DateTime(2026, 1, 1),
    lastPracticedAt: lastPracticedAt,
    isCompleted: isCompleted,
  );
}

PracticeRepertoire _repertoire(List<PracticeSection> sections) {
  return PracticeRepertoire(
    id: 'r1',
    studentId: 's1',
    name: 'Rep',
    startDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    sections: sections,
  );
}

void main() {
  test('picks the latest lastPracticedAt among non-completed sections', () {
    final rep = _repertoire([
      _section(
        id: 'a',
        pieceName: 'Piece A',
        lastPracticedAt: DateTime(2026, 3, 1),
      ),
      _section(
        id: 'b',
        pieceName: 'Piece B',
        lastPracticedAt: DateTime(2026, 3, 5),
      ),
      _section(
        id: 'c',
        pieceName: 'Piece C',
        lastPracticedAt: DateTime(2026, 2, 20),
      ),
    ]);

    final result = mostRecentActivePracticeSection([rep]);

    expect(result?.id, 'b');
    expect(result?.pieceName, 'Piece B');
  });

  test('returns null when no section has been practiced', () {
    final rep = _repertoire([
      _section(id: 'a', pieceName: 'Piece A'),
      _section(id: 'b', pieceName: 'Piece B'),
    ]);

    expect(mostRecentActivePracticeSection([rep]), isNull);
  });

  test('excludes completed sections even if most recently practiced', () {
    final rep = _repertoire([
      _section(
        id: 'done',
        pieceName: 'Done',
        lastPracticedAt: DateTime(2026, 3, 10),
        isCompleted: true,
      ),
      _section(
        id: 'active',
        pieceName: 'Active',
        lastPracticedAt: DateTime(2026, 3, 1),
      ),
    ]);

    final result = mostRecentActivePracticeSection([rep]);

    expect(result?.id, 'active');
  });

  test('returns null for an empty repertoire list', () {
    expect(mostRecentActivePracticeSection(const []), isNull);
  });
}
