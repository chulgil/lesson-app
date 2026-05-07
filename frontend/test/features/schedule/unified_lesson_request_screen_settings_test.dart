import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/unified_lesson_request_screen.dart';
import 'package:lessonaza/features/settings/domain/repositories/settings_repository.dart';
import 'package:lessonaza/features/settings/presentation/providers/settings_repository_provider.dart';

void main() {
  testWidgets(
    'lesson request screen uses target teacher settings for guidance and price',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(
              _FakeSettingsRepository(),
            ),
            teacherAvailabilityRepositoryProvider.overrideWithValue(
              _FakeAvailabilityRepository(),
            ),
          ],
          child: MaterialApp(
            home: UnifiedLessonRequestScreen(
              params: UnifiedLessonRequestParams(
                teacherId: 'target-teacher',
                teacherName: '김선생',
                teacherInstruments: ['피아노'],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('대상 선생님 안내'), findsOneWidget);
      expect(find.text('현재 선생님 안내'), findsNothing);
      expect(find.text('88,000원 / 회'), findsOneWidget);
      expect(find.text('11,000원 / 회'), findsNothing);
    },
  );
}

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<TeacherSettings> getTeacherSettings() async =>
      _settings(id: 'current-teacher', guidance: '현재 선생님 안내', price: 11000);

  @override
  Future<TeacherSettings> getTeacherSettingsById(String teacherId) async =>
      _settings(id: teacherId, guidance: '대상 선생님 안내', price: 88000);

  TeacherSettings _settings({
    required String id,
    required String guidance,
    required int price,
  }) {
    return TeacherSettings(
      id: id,
      instruments: const ['피아노'],
      createdAt: DateTime.utc(2026, 5, 2),
      bookingGuidanceMessage: guidance,
      lessonPriceTable: {
        '피아노': {'beginner': price},
      },
    );
  }

  @override
  Future<TeacherSettings> addCustomDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> removeCustomDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> toggleDuration(int duration, bool isActive) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateAvailableSlots(List<TimeSlot> slots) =>
      throw UnimplementedError();

  @override
  Future<void> updateBookingGuidanceMessage(String? message) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateBreakTime(int minutes) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateDefaultDuration(int duration) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateInstruments(List<String> instruments) =>
      throw UnimplementedError();

  @override
  Future<void> updatePriceTable(Map<String, Map<String, int>> priceTable) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateTimeSlot(TimeSlot slot) =>
      throw UnimplementedError();

  @override
  Future<void> updateTrialLessonFree(bool value) => throw UnimplementedError();

  @override
  Future<TeacherSettings> toggleTimeSlot(String slotId, bool isActive) =>
      throw UnimplementedError();

  @override
  Future<TeacherSettings> updateMinBookingHours(int hours) =>
      throw UnimplementedError();
}

class _FakeAvailabilityRepository implements TeacherAvailabilityRepository {
  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    return TeacherAvailability(
      id: 'availability-$teacherId',
      teacherId: teacherId,
      createdAt: DateTime.utc(2026, 5, 2),
      weeklySchedules: [
        WeeklySchedule(
          id: 'schedule-1',
          dayOfWeek: 0,
          startTime: '09:00',
          endTime: '12:00',
          createdAt: DateTime.utc(2026, 5, 2),
        ),
      ],
    );
  }

  @override
  Future<TeacherAvailability> addException(
    String teacherId,
    TimeException exception,
  ) => throw UnimplementedError();

  @override
  Future<TeacherAvailability> addWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => throw UnimplementedError();

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) => throw UnimplementedError();

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAvailability(String teacherId) =>
      throw UnimplementedError();

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => const [];

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async => const [];

  @override
  Future<List<DateTime>> getNextAvailableDates(
    String teacherId, {
    required DateTime fromDate,
    int limit = 3,
  }) async => const [];

  @override
  Future<List<AvailabilitySlot>> getRecommendedSlots(
    String teacherId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async => const [];

  @override
  Future<TeacherAvailability> removeException(
    String teacherId,
    String exceptionId,
  ) => throw UnimplementedError();

  @override
  Future<TeacherAvailability> removeWeeklySchedule(
    String teacherId,
    String scheduleId,
  ) => throw UnimplementedError();

  @override
  Future<TeacherAvailability> saveAvailability(
    TeacherAvailability availability,
  ) => throw UnimplementedError();

  @override
  Future<void> setTimeBlocks(
    String teacherId,
    DateTime date,
    List<ClockTime> times,
    bool isAvailable,
  ) => throw UnimplementedError();

  @override
  Future<void> toggleTimeBlock(
    String teacherId,
    DateTime date,
    ClockTime time,
    bool isAvailable,
  ) => throw UnimplementedError();

  @override
  Future<TeacherAvailability> updateException(
    String teacherId,
    TimeException exception,
  ) => throw UnimplementedError();

  @override
  Future<TeacherAvailability> updateWeeklySchedule(
    String teacherId,
    WeeklySchedule schedule,
  ) => throw UnimplementedError();
}
