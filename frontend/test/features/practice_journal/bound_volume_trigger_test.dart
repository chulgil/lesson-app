// 트리거 회귀: 곡(레퍼토리) 완성(archive) → 완성본 제본 + 책장 갱신.
//
// 실제 write(archive notifier) → read(boundVolumesProvider) 경로를 검증한다.
// read provider 를 override 하지 않는다 (Oracle Problem — feedback_provider_read_write_split).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_repository_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/repertoire_archive_provider.dart';
import 'package:lessonaza/features/practice_journal/practice_journal_facade.dart';

import '../../test_helper.dart';

void main() {
  setUp(initializeTestEnvironment);
  tearDown(cleanupTestEnvironment);

  test('곡(레퍼토리) 완성(archive) → 완성본 1권 제본 + 책장 갱신', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const studentId = 'student_bind_regression';

    final repo = container.read(practiceRepertoireRepositoryProvider);
    final created = await repo.createRepertoire(
      PracticeRepertoire(
        id: 'ignored',
        studentId: studentId,
        name: '제본 회귀 테스트곡',
        startDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
      ),
    );

    // alive listener — 책장 read 를 살려둔다.
    final sub = container.listen(boundVolumesProvider(studentId), (_, __) {});
    addTearDown(sub.close);

    final before = await container.read(boundVolumesProvider(studentId).future);
    expect(before, isEmpty);

    await container
        .read(repertoireArchiveNotifierProvider.notifier)
        .archive(created.id, studentId);

    final after = await container.read(boundVolumesProvider(studentId).future);
    expect(after.length, 1);
    expect(after.single.pieceId, created.id);
    expect(after.single.pieceName, '제본 회귀 테스트곡');
    expect(after.single.volumeNo, 1);
  });
}
