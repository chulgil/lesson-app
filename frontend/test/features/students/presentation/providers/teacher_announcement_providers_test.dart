import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/students/data/repositories/mock_teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';
import 'package:lessonaza/features/students/presentation/providers/teacher_announcement_providers.dart';

/// Read/write-split regression: after a write (update/delete) the UI invalidates
/// [teacherAnnouncementsProvider], which must refetch from the real repository.
///
/// The repository is overridden (the write target) but the read provider is NOT
/// overridden — we drive a real write, invalidate, and assert the refetch.
class _NoopLessonRepository implements LessonRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late MockTeacherAnnouncementRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockTeacherAnnouncementRepository(
      lessonRepository: _NoopLessonRepository(),
      notificationService: _NoopNotificationService(),
    );
    container = ProviderContainer(
      overrides: [
        teacherAnnouncementRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    // Keep the read provider alive across invalidations (mirrors a mounted UI).
    final sub = container.listen(
      teacherAnnouncementsProvider('t1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
  });

  TeacherAnnouncement general(String message) => TeacherAnnouncement(
    id: '',
    teacherId: 't1',
    type: AnnouncementType.general,
    message: message,
    createdAt: DateTime(2026, 6, 1),
  );

  test('update → invalidate refetches the changed announcement', () async {
    // Seed + invalidate to establish a populated baseline (the create flow
    // invalidates too), then assert the update is picked up after invalidation.
    final saved = await repo.create(general('원본'));
    container.invalidate(teacherAnnouncementsProvider('t1'));
    final initial = await container.read(
      teacherAnnouncementsProvider('t1').future,
    );
    expect(initial.single.message, '원본');

    await repo.update(
      TeacherAnnouncement(
        id: saved.id,
        teacherId: saved.teacherId,
        type: saved.type,
        dates: saved.dates,
        message: '수정',
        createdAt: saved.createdAt,
      ),
    );
    container.invalidate(teacherAnnouncementsProvider('t1'));

    final after = await container.read(
      teacherAnnouncementsProvider('t1').future,
    );
    expect(after.single.id, saved.id);
    expect(after.single.message, '수정');
  });

  test('delete → invalidate refetches the emptied list', () async {
    final saved = await repo.create(general('삭제 대상'));
    container.invalidate(teacherAnnouncementsProvider('t1'));
    final initial = await container.read(
      teacherAnnouncementsProvider('t1').future,
    );
    expect(initial, hasLength(1));

    await repo.delete(saved.id);
    container.invalidate(teacherAnnouncementsProvider('t1'));

    final after = await container.read(
      teacherAnnouncementsProvider('t1').future,
    );
    expect(after, isEmpty);
  });
}
