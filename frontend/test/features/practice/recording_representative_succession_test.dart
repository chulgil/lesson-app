import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/practice/data/repositories/hive_recording_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';

import '../../test_helper.dart';

Recording _rec(
  String id, {
  String repertoireId = 'rep_1',
  required DateTime recordedAt,
  bool isRepresentative = false,
}) {
  return Recording(
    id: id,
    repertoireId: repertoireId,
    studentId: 'student_1',
    type: RecordingType.student,
    localPath: '/tmp/$id.wav',
    durationSeconds: 30,
    recordedAt: recordedAt,
    isRepresentative: isRepresentative,
  );
}

void main() {
  // ── Pure heir rule (#749) ──────────────────────────────────────────────────
  group('Recording.pickRepresentativeHeir', () {
    test('empty → null', () {
      expect(Recording.pickRepresentativeHeir(const []), isNull);
    });

    test('single → that recording', () {
      final r = _rec('a', recordedAt: DateTime(2026, 5, 1));
      expect(Recording.pickRepresentativeHeir([r])?.id, 'a');
    });

    test('multiple → most recent by recordedAt (order-independent)', () {
      final old = _rec('old', recordedAt: DateTime(2026, 5, 1));
      final mid = _rec('mid', recordedAt: DateTime(2026, 5, 3));
      final newest = _rec('newest', recordedAt: DateTime(2026, 5, 9));
      expect(
        Recording.pickRepresentativeHeir([old, newest, mid])?.id,
        'newest',
      );
    });
  });

  // ── Hive repo succession on delete (#749) ──────────────────────────────────
  group('HiveRecordingRepository.deleteRecording succession', () {
    late HiveRecordingRepository repo;

    setUpAll(() async {
      await initializeTestEnvironment();
    });

    setUp(() async {
      final box = await Hive.openBox<Recording>('recordings');
      await box.clear();
      repo = HiveRecordingRepository();
    });

    tearDownAll(() async {
      await cleanupTestEnvironment();
    });

    test('deleting the representative promotes the newest remaining', () async {
      final box = await Hive.openBox<Recording>('recordings');
      await box.put('a', _rec('a', recordedAt: DateTime(2026, 5, 1)));
      await box.put('b', _rec('b', recordedAt: DateTime(2026, 5, 5)));
      await box.put(
        'rep',
        _rec('rep', recordedAt: DateTime(2026, 5, 9), isRepresentative: true),
      );

      await repo.deleteRecording('rep');

      final heir = await repo.getRepresentativeRecording('rep_1');
      // newest remaining is 'b' (2026-05-05 > 2026-05-01)
      expect(heir?.id, 'b');
      expect(box.get('rep'), isNull);
    });

    test('deleting a non-representative keeps the representative', () async {
      final box = await Hive.openBox<Recording>('recordings');
      await box.put(
        'rep',
        _rec('rep', recordedAt: DateTime(2026, 5, 9), isRepresentative: true),
      );
      await box.put('b', _rec('b', recordedAt: DateTime(2026, 5, 5)));

      await repo.deleteRecording('b');

      final heir = await repo.getRepresentativeRecording('rep_1');
      expect(heir?.id, 'rep');
    });

    test('deleting the only recording leaves no representative', () async {
      final box = await Hive.openBox<Recording>('recordings');
      await box.put(
        'rep',
        _rec('rep', recordedAt: DateTime(2026, 5, 9), isRepresentative: true),
      );

      await repo.deleteRecording('rep');

      expect(await repo.getRepresentativeRecording('rep_1'), isNull);
    });

    test('succession is scoped to the same repertoire', () async {
      final box = await Hive.openBox<Recording>('recordings');
      await box.put(
        'rep',
        _rec('rep', recordedAt: DateTime(2026, 5, 9), isRepresentative: true),
      );
      // newer, but a different repertoire → must NOT inherit
      await box.put(
        'other',
        _rec('other', repertoireId: 'rep_2', recordedAt: DateTime(2026, 5, 20)),
      );
      await box.put('same', _rec('same', recordedAt: DateTime(2026, 5, 1)));

      await repo.deleteRecording('rep');

      final heir = await repo.getRepresentativeRecording('rep_1');
      expect(heir?.id, 'same');
    });
  });
}
