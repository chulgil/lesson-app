import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/practice/data/services/loop_stats_sync_service.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_stats.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_loop_stats_repository.dart';

class _FakeRepository implements PracticeLoopStatsRepository {
  List<PendingLoopStatsSync> lastSyncEntries = const [];
  int syncCalls = 0;
  Exception? throwOnSync;
  PracticeLoopStatsSyncResult result = const PracticeLoopStatsSyncResult(
    upserted: 1,
  );

  @override
  Future<({int totalRepeats, List<PracticeLoopStats> rows})> listForStudent({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) async => (totalRepeats: 0, rows: const <PracticeLoopStats>[]);

  @override
  Future<List<StudentRepeatStats>> summary({
    required PracticeLoopStatsWindow window,
  }) async => const [];

  @override
  Future<PracticeLoopStatsSyncResult> syncStudent({
    required List<PendingLoopStatsSync> entries,
  }) async {
    syncCalls++;
    lastSyncEntries = entries;
    if (throwOnSync != null) throw throwOnSync!;
    return result;
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_loop_stats_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(LoopStatsSyncService.boxName);
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('LoopStatsSyncService — #512', () {
    test(
      'enqueue persists per-section entries (one row per section)',
      () async {
        final repo = _FakeRepository();
        final svc = LoopStatsSyncService(repo);

        final now = DateTime.utc(2026, 6, 4, 12);
        await svc.enqueue(
          studentUserId: 'student-a',
          entry: PendingLoopStatsSync(
            sectionId: 'sec-1',
            repeatCount: 3,
            lastPlayedAt: now,
          ),
        );
        await svc.enqueue(
          studentUserId: 'student-a',
          entry: PendingLoopStatsSync(
            sectionId: 'sec-1',
            repeatCount: 5,
            lastPlayedAt: now,
          ),
        );
        await svc.enqueue(
          studentUserId: 'student-a',
          entry: PendingLoopStatsSync(
            sectionId: 'sec-2',
            repeatCount: 2,
            lastPlayedAt: now,
          ),
        );

        final pending = await svc.pendingFor('student-a');
        expect(pending.length, 2);
        // Latest delta wins for the same section.
        final byId = {for (final p in pending) p.sectionId: p.repeatCount};
        expect(byId, {'sec-1': 5, 'sec-2': 2});
      },
    );

    test('flush uploads + clears the queue on success', () async {
      final repo = _FakeRepository();
      final svc = LoopStatsSyncService(repo);

      await svc.enqueue(
        studentUserId: 'student-a',
        entry: PendingLoopStatsSync(
          sectionId: 'sec-1',
          repeatCount: 7,
          lastPlayedAt: DateTime.utc(2026, 6, 4),
        ),
      );

      final result = await svc.flush('student-a');
      expect(repo.syncCalls, 1);
      expect(repo.lastSyncEntries.length, 1);
      expect(repo.lastSyncEntries.single.sectionId, 'sec-1');
      expect(result.upserted, 1);

      final pending = await svc.pendingFor('student-a');
      expect(pending, isEmpty);
    });

    test('flush keeps queue on error for retry', () async {
      final repo = _FakeRepository()..throwOnSync = Exception('network');
      final svc = LoopStatsSyncService(repo);

      await svc.enqueue(
        studentUserId: 'student-a',
        entry: PendingLoopStatsSync(
          sectionId: 'sec-1',
          repeatCount: 7,
          lastPlayedAt: DateTime.utc(2026, 6, 4),
        ),
      );

      await expectLater(svc.flush('student-a'), throwsException);

      final pending = await svc.pendingFor('student-a');
      expect(pending.length, 1, reason: 'queue preserved for retry');
    });

    test('flush is a no-op when queue empty', () async {
      final repo = _FakeRepository();
      final svc = LoopStatsSyncService(repo);
      final result = await svc.flush('student-a');
      expect(repo.syncCalls, 0);
      expect(result.upserted, 0);
    });

    test('queues stay isolated per student user id', () async {
      final repo = _FakeRepository();
      final svc = LoopStatsSyncService(repo);

      await svc.enqueue(
        studentUserId: 'student-a',
        entry: PendingLoopStatsSync(
          sectionId: 'sec-1',
          repeatCount: 3,
          lastPlayedAt: DateTime.utc(2026, 6, 4),
        ),
      );
      await svc.enqueue(
        studentUserId: 'student-b',
        entry: PendingLoopStatsSync(
          sectionId: 'sec-1',
          repeatCount: 5,
          lastPlayedAt: DateTime.utc(2026, 6, 4),
        ),
      );

      expect((await svc.pendingFor('student-a')).single.repeatCount, 3);
      expect((await svc.pendingFor('student-b')).single.repeatCount, 5);
    });
  });
}
