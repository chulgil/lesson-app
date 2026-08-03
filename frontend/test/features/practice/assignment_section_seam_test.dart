import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:lessonaza/features/practice/data/models/practice_recording_hive_adapter.dart';
import 'package:lessonaza/features/practice/data/repositories/impl/mock_practice_repertoire_impl.dart';
import 'package:lessonaza/features/practice/data/repositories/mock_practice_item_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_item_providers.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_repository_provider.dart';

/// #611·#612 — 과제 → 학생 레퍼토리 이음새 회귀.
///
/// 버그(0625): sheet 가 마디범위 가진 섹션을 명시 생성한 뒤, addItem 이
/// `_syncToStudentRepertoire` 로 기본('선생님 과제') 레퍼토리에 `rangeType:full`
/// 두 번째 섹션을 만들어 (a) 중복 + (b) 범위 소실.
///
/// 수정(Option A): 명시 섹션을 단일 소스로, 그 섹션에 과제 메타데이터만 부착.
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

  test('과제 추가 시 명시 섹션에 메타데이터 부착(범위 보존)·중복 섹션 0', () async {
    final repertoireRepo = MockPracticeRepertoireRepository();
    final itemRepo = MockPracticeItemRepository();

    // 교사가 레퍼토리 + 마디범위(5~8) 섹션을 명시 생성 (sheet 경로).
    final rep = await repertoireRepo.createRepertoire(
      PracticeRepertoire(
        id: '',
        studentId: 's1',
        name: '베토벤 소나타',
        sections: const [],
        startDate: DateTime(2026, 6, 29),
        createdAt: DateTime(2026, 6, 29),
      ),
    );
    final section = await repertoireRepo.createSection(
      PracticeSection(
        id: '',
        repertoireId: rep.id,
        pieceName: '소나타 8번',
        rangeType: SectionRangeType.measure,
        startMeasure: 5,
        endMeasure: 8,
        createdAt: DateTime(2026, 6, 29),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        practiceRepertoireRepositoryProvider.overrideWithValue(repertoireRepo),
        practiceItemRepositoryProvider.overrideWithValue(itemRepo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(practiceItemsNotifierProvider('lesson-1').notifier)
        .addItem(
          studentId: 's1',
          teacherId: 't1',
          title: '소나타 8번 5~8마디',
          sectionId: section.id,
        );

    // #612 — 명시 섹션이 범위(5~8/measure)를 유지 + 과제 메타데이터 부착.
    final updated = await repertoireRepo.getSection(section.id);
    expect(updated, isNotNull);
    expect(updated!.startMeasure, 5);
    expect(updated.endMeasure, 8);
    expect(updated.rangeType, SectionRangeType.measure);
    expect(updated.practiceItemId, isNotNull);
    expect(updated.practiceItemId, isNotEmpty);
    expect(updated.assignedByTeacherId, 't1');

    // #611 — 기본 레퍼토리에 중복 섹션을 만들지 않음 (전체 섹션 1개).
    final reps = await repertoireRepo.getRepertoires('s1');
    final totalSections = reps.fold<int>(
      0,
      (sum, r) => sum + r.sections.length,
    );
    expect(totalSections, 1);
  });
}
