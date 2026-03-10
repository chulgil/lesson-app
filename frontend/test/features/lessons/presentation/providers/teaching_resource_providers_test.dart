import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lessonaza/features/lessons/presentation/providers/teaching_resource_providers.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late MockTeachingResourceRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockTeachingResourceRepository();
    container = createTestContainer(
      overrides: [
        teachingResourceRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(createTeachingResource());
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // teacherResourcesProvider
  // ═══════════════════════════════════════════════════════════════════════════

  group('teacherResourcesProvider', () {
    test('해당 선생님의 자료 목록 반환', () async {
      final resources = [
        createTeachingResource(id: 'tr_1', title: 'Resource 1'),
        createTeachingResource(id: 'tr_2', title: 'Resource 2'),
      ];

      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => resources);

      final result =
          await container.read(teacherResourcesProvider('teacher_1').future);

      expect(result, resources);
      expect(result.length, 2);
      verify(() => mockRepo.getByTeacherId('teacher_1')).called(1);
    });

    test('존재하지 않는 선생님 → 빈 리스트', () async {
      when(() => mockRepo.getByTeacherId('unknown'))
          .thenAnswer((_) async => []);

      final result =
          await container.read(teacherResourcesProvider('unknown').future);

      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // resourcesByIdsProvider
  // ═══════════════════════════════════════════════════════════════════════════

  group('resourcesByIdsProvider', () {
    test('주어진 ID에 해당하는 자료 반환', () async {
      final resources = [
        createTeachingResource(id: 'tr_1'),
        createTeachingResource(id: 'tr_3'),
      ];

      when(() => mockRepo.getByIds(['tr_1', 'tr_3']))
          .thenAnswer((_) async => resources);

      final result = await container
          .read(resourcesByIdsProvider(['tr_1', 'tr_3']).future);

      expect(result.length, 2);
      verify(() => mockRepo.getByIds(['tr_1', 'tr_3'])).called(1);
    });

    test('빈 ID 목록 → Repository 호출 없이 빈 리스트', () async {
      final result =
          await container.read(resourcesByIdsProvider([]).future);

      expect(result, isEmpty);
      verifyNever(() => mockRepo.getByIds(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TeachingResourceNotifier
  // ═══════════════════════════════════════════════════════════════════════════

  group('TeachingResourceNotifier', () {
    test('build()에서 선생님 자료 로드', () async {
      final resources = [
        createTeachingResource(id: 'tr_1'),
      ];

      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => resources);

      final result = await container
          .read(teachingResourceNotifierProvider.future);

      expect(result, resources);
    });

    test('addYoutubeResource()로 자료 추가 후 목록 갱신', () async {
      final created = createTeachingResource(id: 'tr_new', title: 'New');

      // build() call
      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => []);

      // create() call
      when(() => mockRepo.create(any()))
          .thenAnswer((_) async => created);

      // Wait for initial build
      await container.read(teachingResourceNotifierProvider.future);

      // After create, getByTeacherId returns updated list
      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => [created]);

      final result = await container
          .read(teachingResourceNotifierProvider.notifier)
          .addYoutubeResource(
            title: 'New',
            youtubeUrl: 'https://youtube.com/watch?v=test123test1',
          );

      expect(result.id, 'tr_new');
      verify(() => mockRepo.create(any())).called(1);
    });

    test('deleteResource()로 자료 삭제 후 목록 갱신', () async {
      final resource = createTeachingResource(id: 'tr_1');

      // build() call
      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => [resource]);

      // delete() call
      when(() => mockRepo.delete('tr_1'))
          .thenAnswer((_) async {});

      // Wait for initial build
      await container.read(teachingResourceNotifierProvider.future);

      // After delete, getByTeacherId returns empty list
      when(() => mockRepo.getByTeacherId('teacher_1'))
          .thenAnswer((_) async => []);

      await container
          .read(teachingResourceNotifierProvider.notifier)
          .deleteResource('tr_1');

      verify(() => mockRepo.delete('tr_1')).called(1);
    });
  });
}
