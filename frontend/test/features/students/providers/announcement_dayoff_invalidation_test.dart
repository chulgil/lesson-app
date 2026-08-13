// A1 (audit 2026-07-10) — announcement writes (create/update/delete) only
// invalidated `teacherAnnouncementsProvider`. `teacherDayOffsProvider` is what
// the weekly grid / time picker / subscription detail watch, so a new 휴강 did
// not appear (that day stayed bookable) until a cold reload.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/students/data/repositories/mock_teacher_announcement_repository.dart';
import 'package:lessonaza/features/students/domain/entities/teacher_announcement.dart';
import 'package:lessonaza/features/students/presentation/providers/teacher_announcement_providers.dart';

/// Silent no-op — the dayOff create path fires notifications; the real
/// service would touch the platform plugin (absent in unit tests, causing a
/// LateInitializationError flake depending on test order).
class _SilentNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showNotification(AppNotification notification) async {}

  @override
  Future<void> scheduleNotification(AppNotification notification) async {}

  @override
  Future<void> cancelNotification(String id) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Stream<AppNotification> get onNotificationTapped => const Stream.empty();
}

void main() {
  const teacherId = 'teacher_1';
  final dayOff = DateTime(2026, 8, 14);

  test('공지 쓰기 무효화가 휴강일(dayOffs) 읽기 provider 도 재요청시킨다', () async {
    final container = ProviderContainer(
      overrides: [
        mockDataModeProvider.overrideWithValue(true),
        teacherAnnouncementRepositoryProvider.overrideWith(
          (ref) => MockTeacherAnnouncementRepository(
            lessonRepository: ref.watch(lessonRepositoryProvider),
            notificationService: _SilentNotificationService(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = teacherDayOffsProvider(
      teacherId: teacherId,
      fromDate: DateTime(2026, 8, 1),
      toDate: DateTime(2026, 8, 31),
    );

    // Live listener keeps the cached value — this is what a screen does.
    final sub = container.listen(provider, (_, __) {}, fireImmediately: true);
    addTearDown(sub.close);

    final before = (await container.read(provider.future)).length;

    final repo = container.read(teacherAnnouncementRepositoryProvider);
    await repo.create(
      TeacherAnnouncement(
        id: 'ann_dayoff_test',
        teacherId: teacherId,
        type: AnnouncementType.dayOff,
        dates: [dayOff],
        message: '휴강합니다',
        createdAt: DateTime(2026, 8, 1),
      ),
    );

    invalidateAnnouncementViews(container, teacherId);

    final after = (await container.read(provider.future)).length;
    expect(
      after,
      before + 1,
      reason: '공지 쓰기가 dayOffs 를 무효화하지 않으면 주간 그리드가 stale (A1)',
    );
  });

  test('공지 쓰기 경로 4곳이 모두 invalidateAnnouncementViews 를 호출한다', () {
    // Static guard: the UI write paths are widget flows that are impractical to
    // drive here, so assert none of them fall back to the announcements-only
    // invalidation that caused A1.
    final files = [
      File(
        'lib/features/students/presentation/widgets/announcement_sheet.dart',
      ),
      File(
        'lib/features/students/presentation/screens/announcement_history_screen.dart',
      ),
    ];

    for (final file in files) {
      final src = file.readAsStringSync();
      expect(
        src.contains('ref.invalidate(teacherAnnouncementsProvider('),
        isFalse,
        reason: '${file.path}: 공지 리스트만 무효화하면 dayOffs 가 stale (A1)',
      );
      expect(
        src.contains('invalidateAnnouncementViews('),
        isTrue,
        reason: '${file.path}: 공통 무효화 헬퍼를 사용해야 함',
      );
    }
  });
}
