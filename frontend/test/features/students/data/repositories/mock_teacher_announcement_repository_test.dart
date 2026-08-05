import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/students/data/repositories/mock_teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';

/// Unit tests for [MockTeacherAnnouncementRepository] update/delete.
///
/// `general` announcements skip the day-off lesson lookup + notification path,
/// so the collaborators are never invoked (noop stubs assert this by throwing).
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

  setUp(() {
    repo = MockTeacherAnnouncementRepository(
      lessonRepository: _NoopLessonRepository(),
      notificationService: _NoopNotificationService(),
    );
  });

  TeacherAnnouncement general(String message) => TeacherAnnouncement(
    id: '',
    teacherId: 't1',
    type: AnnouncementType.general,
    message: message,
    createdAt: DateTime(2026, 6, 1),
  );

  test(
    'update replaces the matching entry — list reflects the new message',
    () async {
      final saved = await repo.create(general('원본 메시지'));
      expect((await repo.getByTeacherId('t1')).single.message, '원본 메시지');

      final updated = await repo.update(
        TeacherAnnouncement(
          id: saved.id,
          teacherId: saved.teacherId,
          type: saved.type,
          dates: saved.dates,
          message: '수정된 메시지',
          createdAt: saved.createdAt,
          affectedLessons: saved.affectedLessons,
        ),
      );

      expect(updated.message, '수정된 메시지');
      final list = await repo.getByTeacherId('t1');
      expect(list, hasLength(1));
      expect(list.single.id, saved.id);
      expect(list.single.message, '수정된 메시지');
    },
  );

  test('delete removes the entry by id — list becomes empty', () async {
    final saved = await repo.create(general('삭제 대상'));
    expect(await repo.getByTeacherId('t1'), hasLength(1));

    await repo.delete(saved.id);

    expect(await repo.getByTeacherId('t1'), isEmpty);
  });

  test('delete only removes the matching id — siblings remain', () async {
    final a = await repo.create(general('첫 번째'));
    // Mock ids derive from millisecondsSinceEpoch; space creates so the two
    // announcements get distinct ids.
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(general('두 번째'));

    await repo.delete(a.id);

    final list = await repo.getByTeacherId('t1');
    expect(list, hasLength(1));
    expect(list.single.message, '두 번째');
  });
}
