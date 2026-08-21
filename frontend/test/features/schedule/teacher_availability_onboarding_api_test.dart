// #1293 — mock 모드에서 첫 가용시간 온보딩 저장이 실 HTTP 를 치지 않아야 한다.
//
// `teacherAvailabilityApiProvider` 는 데이터 모드에 따라 분기한다:
// - mock: `LocalTeacherAvailabilityApi` — mock 게이팅된 availability
//   repository 에 주간 스케줄로 저장 (HTTP 없음)
// - remote: `RemoteTeacherAvailabilityApi` — 기존 BE dual-write 엔드포인트

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/schedule/data/services/teacher_availability_onboarding_api.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/schedule_facade.dart'
    show teacherAvailabilityApiProvider, teacherAvailabilityRepositoryProvider;

class _FakeAvailabilityRepository implements TeacherAvailabilityRepository {
  TeacherAvailability? stored;
  TeacherAvailability? lastSaved;

  _FakeAvailabilityRepository({this.stored});

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async =>
      stored;

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) async {
    lastSaved = availability;
    stored = availability;
    return availability;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TimeSlot _slot(int dayOfWeek) => TimeSlot(
  id: 'slot-$dayOfWeek',
  dayOfWeek: dayOfWeek,
  startTime: const ClockTime(hour: 14, minute: 0),
  endTime: const ClockTime(hour: 18, minute: 0),
);

void main() {
  group('LocalTeacherAvailabilityApi (#1293)', () {
    test('기존 availability 에 주간 스케줄을 병합 저장한다 (HTTP 없음)', () async {
      final existing = TeacherAvailability(
        id: 'availability-teacher_1',
        teacherId: 'teacher_1',
        weeklySchedules: [
          WeeklySchedule(
            id: 'existing-1',
            dayOfWeek: 5, // Saturday (0=Mon)
            startTime: '10:00',
            endTime: '12:00',
            createdAt: DateTime(2026),
          ),
        ],
        createdAt: DateTime(2026),
      );
      final repo = _FakeAvailabilityRepository(stored: existing);
      final api = LocalTeacherAvailabilityApi(
        repository: repo,
        teacherIdResolver: () => 'teacher_1',
      );

      // TimeSlot.dayOfWeek: 1=Mon..7=Sun → WeeklySchedule.dayOfWeek: 0=Mon..6=Sun
      final result = await api.postOnboarding([_slot(1), _slot(3)]);

      final saved = repo.lastSaved;
      expect(saved, isNotNull);
      expect(saved!.teacherId, 'teacher_1');
      expect(saved.weeklySchedules, hasLength(3));
      final added = saved.weeklySchedules.skip(1).toList();
      expect(added.map((s) => s.dayOfWeek), [0, 2]);
      expect(added.every((s) => s.startTime == '14:00'), isTrue);
      expect(added.every((s) => s.endTime == '18:00'), isTrue);
      expect(added.every((s) => s.isActive), isTrue);
      expect(result.scheduleSlotCount, 2);
      expect(result.settingsSlotCount, 2);
    });

    test('availability 가 없으면 teacherId 앵커로 새로 만들어 저장한다', () async {
      final repo = _FakeAvailabilityRepository();
      final api = LocalTeacherAvailabilityApi(
        repository: repo,
        teacherIdResolver: () => 'teacher_9',
      );

      await api.postOnboarding([_slot(7)]);

      final saved = repo.lastSaved;
      expect(saved, isNotNull);
      expect(saved!.teacherId, 'teacher_9');
      expect(saved.weeklySchedules, hasLength(1));
      expect(saved.weeklySchedules.single.dayOfWeek, 6); // Sun
    });
  });

  group('teacherAvailabilityApiProvider 데이터 모드 분기 (#1293)', () {
    test('mock 모드면 LocalTeacherAvailabilityApi 를 반환한다', () {
      final container = ProviderContainer(
        overrides: [
          mockDataModeProvider.overrideWith((ref) => true),
          currentUserIdProvider.overrideWith((ref) => 'teacher_1'),
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _FakeAvailabilityRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(teacherAvailabilityApiProvider),
        isA<LocalTeacherAvailabilityApi>(),
      );
    });

    test('remote 모드면 RemoteTeacherAvailabilityApi 를 반환한다', () {
      final container = ProviderContainer(
        overrides: [mockDataModeProvider.overrideWith((ref) => false)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(teacherAvailabilityApiProvider),
        isA<RemoteTeacherAvailabilityApi>(),
      );
    });
  });
}
