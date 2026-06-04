import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/constants/practice_defaults.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repertoire_repository.dart';
import 'package:lessonaza/features/practice/domain/services/quick_recording_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// In-memory fake repository (only the methods QuickRecordingService touches)
// ═══════════════════════════════════════════════════════════════════════════

class _FakePracticeRepertoireRepository
    implements PracticeRepertoireRepository {
  final Map<String, PracticeRepertoire> _repertoires = {};
  final Map<String, PracticeSection> _sections = {};

  int createRepertoireCalls = 0;
  int createSectionCalls = 0;

  @override
  Future<PracticeRepertoire?> getRepertoire(String id) async =>
      _repertoires[id];

  @override
  Future<PracticeRepertoire> createRepertoire(
    PracticeRepertoire repertoire,
  ) async {
    createRepertoireCalls++;
    _repertoires[repertoire.id] = repertoire;
    return repertoire;
  }

  @override
  Future<PracticeSection?> getSection(String id) async => _sections[id];

  @override
  Future<PracticeSection> createSection(PracticeSection section) async {
    createSectionCalls++;
    _sections[section.id] = section;
    return section;
  }

  // ─── Unused methods — throw to fail loudly if accidentally invoked ────────
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: ${invocation.memberName}');
  }
}

void main() {
  group('QuickRecordingService.ensureDefaultsForStudent', () {
    late _FakePracticeRepertoireRepository repo;
    late QuickRecordingService service;

    setUp(() {
      repo = _FakePracticeRepertoireRepository();
      service = QuickRecordingService(repo);
    });

    test('throws ArgumentError when studentId is empty', () async {
      expect(() => service.ensureDefaultsForStudent(''), throwsArgumentError);
    });

    test('creates default repertoire and section on first call', () async {
      const studentId = 'student_42';

      final target = await service.ensureDefaultsForStudent(studentId);

      expect(
        target.repertoire.id,
        equals(PracticeDefaults.defaultRepertoireIdFor(studentId)),
      );
      expect(target.repertoire.name, equals(PracticeDefaults.repertoireName));
      expect(target.repertoire.isDefault, isTrue);
      expect(target.repertoire.studentId, equals(studentId));

      expect(
        target.section.id,
        equals(PracticeDefaults.defaultQuickRecordSectionIdFor(studentId)),
      );
      expect(
        target.section.sectionName,
        equals(PracticeDefaults.quickRecordSectionName),
      );
      expect(target.section.isDefault, isTrue);
      expect(target.section.repertoireId, equals(target.repertoire.id));
      expect(target.section.rangeType, equals(SectionRangeType.full));

      expect(repo.createRepertoireCalls, equals(1));
      expect(repo.createSectionCalls, equals(1));
    });

    test(
      'is idempotent — repeated calls return same pair without re-creating',
      () async {
        const studentId = 'student_42';

        final first = await service.ensureDefaultsForStudent(studentId);
        final second = await service.ensureDefaultsForStudent(studentId);
        final third = await service.ensureDefaultsForStudent(studentId);

        expect(second.repertoire.id, equals(first.repertoire.id));
        expect(second.section.id, equals(first.section.id));
        expect(third.repertoire.id, equals(first.repertoire.id));
        expect(third.section.id, equals(first.section.id));

        // Only the very first call should have invoked create*.
        expect(repo.createRepertoireCalls, equals(1));
        expect(repo.createSectionCalls, equals(1));
      },
    );

    test('produces distinct defaults per student', () async {
      final a = await service.ensureDefaultsForStudent('alice');
      final b = await service.ensureDefaultsForStudent('bob');

      expect(a.repertoire.id, isNot(equals(b.repertoire.id)));
      expect(a.section.id, isNot(equals(b.section.id)));
      expect(a.repertoire.studentId, equals('alice'));
      expect(b.repertoire.studentId, equals('bob'));

      expect(repo.createRepertoireCalls, equals(2));
      expect(repo.createSectionCalls, equals(2));
    });

    test(
      'reuses existing default repertoire even when section is missing',
      () async {
        const studentId = 'student_99';
        // Pre-seed only the repertoire, no section.
        final repertoireId = PracticeDefaults.defaultRepertoireIdFor(studentId);
        final seededAt = DateTime(2026, 1, 1);
        await repo.createRepertoire(
          PracticeRepertoire(
            id: repertoireId,
            studentId: studentId,
            name: PracticeDefaults.repertoireName,
            startDate: seededAt,
            createdAt: seededAt,
            isDefault: true,
          ),
        );
        repo.createRepertoireCalls = 0; // reset after seeding
        repo.createSectionCalls = 0;

        final target = await service.ensureDefaultsForStudent(studentId);

        expect(target.repertoire.id, equals(repertoireId));
        expect(target.repertoire.createdAt, equals(seededAt));
        expect(target.section.repertoireId, equals(repertoireId));
        expect(target.section.isDefault, isTrue);

        // Repertoire reused → 0 creates. Section missing → 1 create.
        expect(repo.createRepertoireCalls, equals(0));
        expect(repo.createSectionCalls, equals(1));
      },
    );
  });
}
