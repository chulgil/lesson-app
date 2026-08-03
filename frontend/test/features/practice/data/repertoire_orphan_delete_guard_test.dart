import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/features/practice/data/models/practice_recording_hive_adapter.dart';
import 'package:lessonaza/features/practice/data/repositories/impl/mock_practice_repertoire_impl.dart';
import 'package:lessonaza/features/practice/data/repositories/impl/practice_repository_base.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';

/// #1195 재감사(2026-07-21) — 레퍼토리 CRUD 데이터손실 race 가드.
///
/// 버그: create/update/delete·section 뮤테이션이 read 와 달리 [ensureInitialized]
/// 를 기다리지 않아, 초기 Hive 로드 전에 실행되면 [saveRepertoiresToHive] 의
/// orphan-delete 가 아직 메모리 맵에 안 올라온 영속 레퍼토리를 Hive 에서 지웠다.
/// 수정: orphan-delete 를 isInitialized 로 가드 — 로드 완료 후에만 삭제.
void main() {
  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(PracticeRecordingAdapter().typeId)) {
      Hive.registerAdapter(PracticeRecordingAdapter());
    }
  });
  tearDown(() async {
    await tearDownTestHive();
  });

  PracticeRepertoire rep(String id) => PracticeRepertoire(
    id: id,
    studentId: 's1',
    name: 'r-$id',
    sections: const [],
    startDate: DateTime(2026, 7, 21),
    createdAt: DateTime(2026, 7, 21),
  );

  test('미초기화 상태의 저장은 영속 레퍼토리를 지우지 않는다 (데이터손실 가드)', () async {
    // 기존 영속 레퍼토리를 Hive 에 직접 심는다.
    final box = await Hive.openBox(PracticeRepositoryBase.repertoiresBoxName);
    await box.put('existing', jsonEncode(rep('existing').toJson()));

    final repo = MockPracticeRepertoireRepository();
    await repo.ensureInitialized();

    // 초기 로드 전 뮤테이션 상황 재현: 메모리 맵에는 새 항목만, 아직 미초기화.
    repo.repertoires
      ..clear()
      ..['s1'] = [rep('brand-new')];
    repo.isInitialized = false;

    await repo.saveRepertoiresToHive();

    expect(
      box.containsKey('existing'),
      isTrue,
      reason: '미초기화 orphan-delete 가 기존 영속 데이터를 지우면 안 된다',
    );
    expect(box.containsKey('brand-new'), isTrue);
  });

  test('초기화 완료 후에는 orphan-delete 가 정상 제거한다', () async {
    final box = await Hive.openBox(PracticeRepositoryBase.repertoiresBoxName);
    await box.put('stale', jsonEncode(rep('stale').toJson()));

    final repo = MockPracticeRepertoireRepository();
    await repo.ensureInitialized();

    // 맵에서 사라진 항목은 초기화 완료 상태의 저장에서 Hive 에서도 제거된다.
    repo.repertoires
      ..clear()
      ..['s1'] = [rep('kept')];
    repo.isInitialized = true;

    await repo.saveRepertoiresToHive();

    expect(box.containsKey('kept'), isTrue);
    expect(
      box.containsKey('stale'),
      isFalse,
      reason: '초기화 완료 후에는 orphan-delete 가 정상 제거해야 한다',
    );
  });
}
