import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../notifications/notifications_facade.dart';
import '../../data/repositories/mock_teacher_announcement_repository.dart';
import '../../data/repositories/remote_teacher_announcement_repository.dart';
import '../../domain/entities/teacher_announcement.dart';
import '../../domain/repositories/teacher_announcement_repository.dart';

part 'teacher_announcement_providers.g.dart';

/// Repository provider for teacher announcements.
@Riverpod(keepAlive: true)
TeacherAnnouncementRepository teacherAnnouncementRepository(Ref ref) {
  return createRepository<TeacherAnnouncementRepository>(
    ref: ref,
    mock:
        () => MockTeacherAnnouncementRepository(
          lessonRepository: ref.watch(lessonRepositoryProvider),
          notificationService: ref.watch(notificationServiceProvider),
        ),
    remote: (api) => RemoteTeacherAnnouncementRepository(api),
  );
}

/// 선생님의 휴강일 목록 (특정 기간).
/// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
@riverpod
Future<List<DateTime>> teacherDayOffs(
  Ref ref, {
  required String teacherId,
  required DateTime fromDate,
  required DateTime toDate,
}) async {
  final repository = ref.watch(teacherAnnouncementRepositoryProvider);
  return repository.getDayOffs(
    teacherId: teacherId,
    from: fromDate,
    to: toDate,
  );
}

/// 선생님의 공지 목록.
@riverpod
Future<List<TeacherAnnouncement>> teacherAnnouncements(
  Ref ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherAnnouncementRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}
