// Test for TeacherSettingsMigration (W1 Task 1.4).
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §5.4
//   - availableSlots → weeklySchedules 복사
//   - breakTimeBetweenLessons 충돌 → schedule 우선 (운영시간 묶음 SSOT)
//   - minBookingHours 충돌 → profile 우선 (수업방식 묶음 SSOT, 반대 방향)
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/settings/data/migrations/teacher_settings_migration.dart';

void main() {
  group('TeacherSettingsMigration (W1 Task 1.4)', () {
    // Fixed clock to keep generated WeeklySchedule.createdAt deterministic
    // across test calls.
    final fixedClock = DateTime.utc(2026, 6, 11);

    // ------- helpers (DRY) -------
    TeacherSettings buildSettings({
      // ignore: deprecated_member_use_from_same_package
      List<TimeSlot> availableSlots = const [],
      int breakTimeBetweenLessons = 0,
      int minBookingHours = 24,
    }) {
      // Constructor uses deprecated params; suppression is intentional —
      // migration logic must read the deprecated fields.
      // ignore: deprecated_member_use_from_same_package
      return TeacherSettings(
        id: 'settings-1',
        instruments: const ['바이올린'],
        availableSlots: availableSlots,
        createdAt: fixedClock,
        breakTimeBetweenLessons: breakTimeBetweenLessons,
        minBookingHours: minBookingHours,
      );
    }

    TeacherAvailability buildAvailability({
      List<WeeklySchedule> weeklySchedules = const [],
      int breakTimeBetweenLessons = 10,
      int minBookingHours = 24,
    }) {
      return TeacherAvailability(
        id: 'availability-1',
        teacherId: 'teacher-1',
        weeklySchedules: weeklySchedules,
        createdAt: fixedClock,
        breakTimeBetweenLessons: breakTimeBetweenLessons,
        minBookingHours: minBookingHours,
      );
    }

    TimeSlot buildSlot({
      String id = 'slot-mon',
      int dayOfWeek = 1, // 1 = Monday in TimeSlot
      int startHour = 14,
      int endHour = 18,
    }) {
      return TimeSlot(
        id: id,
        dayOfWeek: dayOfWeek,
        startTime: ClockTime(hour: startHour, minute: 0),
        endTime: ClockTime(hour: endHour, minute: 0),
      );
    }

    WeeklySchedule buildSchedule({
      String id = 'sched-tue',
      int dayOfWeek = 1, // 0 = Monday in WeeklySchedule
      String startTime = '10:00',
      String endTime = '13:00',
    }) {
      return WeeklySchedule(
        id: id,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        createdAt: fixedClock,
      );
    }

    group('availableSlots → weeklySchedules', () {
      test(
        '신규 — profile.availableSlots 있고 schedule.weeklySchedules 비어있음 → 복사',
        () {
          final settings = buildSettings(availableSlots: [buildSlot()]);
          final availability = buildAvailability(weeklySchedules: const []);

          final result = TeacherSettingsMigration.migrate(
            settings: settings,
            availability: availability,
          );

          expect(result.changed, isTrue);
          expect(result.availability.weeklySchedules, hasLength(1));
          // Monday: TimeSlot(1) → WeeklySchedule(0) — spec §3 schedule SSOT.
          expect(result.availability.weeklySchedules.first.dayOfWeek, 0);
          expect(result.availability.weeklySchedules.first.startTime, '14:00');
          expect(result.availability.weeklySchedules.first.endTime, '18:00');
          // ignore: deprecated_member_use_from_same_package
          expect(result.settings.availableSlots, isEmpty);
        },
      );

      test('기존 — 둘 다 있음 → schedule 우선 + settings.availableSlots 비움', () {
        final settings = buildSettings(availableSlots: [buildSlot()]);
        final existing = buildSchedule();
        final availability = buildAvailability(weeklySchedules: [existing]);

        final result = TeacherSettingsMigration.migrate(
          settings: settings,
          availability: availability,
        );

        expect(result.changed, isTrue);
        // schedule 보존 — profile slot 무시
        expect(result.availability.weeklySchedules, [existing]);
        // ignore: deprecated_member_use_from_same_package
        expect(result.settings.availableSlots, isEmpty);
      });

      test('이미 완료 — settings.availableSlots 비어있음 → 무영향', () {
        final existing = buildSchedule();
        final settings = buildSettings(availableSlots: const []);
        final availability = buildAvailability(weeklySchedules: [existing]);

        final result = TeacherSettingsMigration.migrate(
          settings: settings,
          availability: availability,
        );

        expect(result.changed, isFalse);
        expect(result.availability.weeklySchedules, [existing]);
        // ignore: deprecated_member_use_from_same_package
        expect(result.settings.availableSlots, isEmpty);
        // 동일 인스턴스 — 무영향 보장
        expect(identical(result.settings, settings), isTrue);
        expect(identical(result.availability, availability), isTrue);
      });
    });

    group('충돌 처리', () {
      test('breakTimeBetweenLessons 다름 → schedule 우선 (운영시간 묶음 SSOT)', () {
        // profile=5분, schedule=15분 → schedule(15) 우선.
        final settings = buildSettings(breakTimeBetweenLessons: 5);
        final availability = buildAvailability(breakTimeBetweenLessons: 15);

        final result = TeacherSettingsMigration.migrate(
          settings: settings,
          availability: availability,
        );

        expect(result.changed, isTrue);
        // schedule 변경 없음 — 운영시간 묶음 SSOT
        expect(result.availability.breakTimeBetweenLessons, 15);
        // profile 의 deprecated 필드 비움 (0)
        // ignore: deprecated_member_use_from_same_package
        expect(result.settings.breakTimeBetweenLessons, 0);
      });

      test('minBookingHours 다름 → profile 우선 (수업방식 묶음 SSOT, 반대 방향)', () {
        // profile=48, schedule=12 → profile(48) 이 SSOT.
        final settings = buildSettings(minBookingHours: 48);
        final availability = buildAvailability(minBookingHours: 12);

        final result = TeacherSettingsMigration.migrate(
          settings: settings,
          availability: availability,
        );

        expect(result.changed, isTrue);
        expect(result.settings.minBookingHours, 48);
        // schedule 의 중복본은 profile 값으로 정렬 (architect P1 #3 정합)
        expect(result.availability.minBookingHours, 48);
      });

      test('breakTimeBetweenLessons 동일 → 무영향', () {
        // 둘 다 10분 + availableSlots 비어있음 → 마이그레이션 불필요.
        final settings = buildSettings(breakTimeBetweenLessons: 10);
        final availability = buildAvailability(breakTimeBetweenLessons: 10);

        final result = TeacherSettingsMigration.migrate(
          settings: settings,
          availability: availability,
        );

        expect(result.changed, isFalse);
        // ignore: deprecated_member_use_from_same_package
        expect(result.settings.breakTimeBetweenLessons, 10);
        expect(result.availability.breakTimeBetweenLessons, 10);
      });
    });
  });
}
