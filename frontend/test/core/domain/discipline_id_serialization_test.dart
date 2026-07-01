import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';

/// #963 — `disciplineId` (nullable) on Lesson / Subscription / TeacherProfile.
///
/// Contract:
/// - JSON key is `discipline_id` (build.yaml `field_rename: snake`) — the agreed
///   BE sync key.
/// - Legacy rows without the key deserialize to `disciplineId == null`
///   (non-destructive migration — 기존 데이터 무손상).
/// - `null` means the music vertical, resolved via [DisciplineRegistry.fallback].
void main() {
  Lesson lesson({String? disciplineId}) => Lesson(
    id: 'lesson_1',
    studentId: 'student_1',
    studentName: '김민수',
    instrument: '바이올린',
    disciplineId: disciplineId,
    date: DateTime(2026, 6, 26),
    startTime: '14:00',
    createdAt: DateTime(2026, 3, 1),
  );

  Subscription subscription({String? disciplineId}) => Subscription(
    id: 'sub_1',
    studentId: 'student_1',
    membershipId: 'cm_1',
    disciplineId: disciplineId,
    type: SubscriptionType.package,
    amount: 200000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 3, 1),
  );

  TeacherProfile teacher({String? disciplineId}) => TeacherProfile(
    id: 'tp_1',
    userId: 'user_1',
    name: '이선생',
    instruments: const ['바이올린'],
    disciplineId: disciplineId,
    introduction: '안녕하세요 바이올린 강사입니다.',
    createdAt: DateTime(2026, 3, 1),
  );

  group('disciplineId 직렬화 — discipline_id 키 (BE 동기화 키)', () {
    test('Lesson: 명시값이 discipline_id 로 직렬화·역직렬화 보존', () {
      final json = lesson(disciplineId: 'music').toJson();
      expect(json['discipline_id'], 'music');
      expect(Lesson.fromJson(json).disciplineId, 'music');
    });

    test('Subscription: 명시값이 discipline_id 로 직렬화·역직렬화 보존', () {
      final json = subscription(disciplineId: 'fitness').toJson();
      expect(json['discipline_id'], 'fitness');
      expect(Subscription.fromJson(json).disciplineId, 'fitness');
    });

    test('TeacherProfile: 명시값이 discipline_id 로 직렬화·역직렬화 보존', () {
      final json = teacher(disciplineId: 'language').toJson();
      expect(json['discipline_id'], 'language');
      expect(TeacherProfile.fromJson(json).disciplineId, 'language');
    });
  });

  group('legacy 무손상 — discipline_id 키 부재 시 null', () {
    test('Lesson: 키 없는 JSON → disciplineId null', () {
      final json = lesson().toJson()..remove('discipline_id');
      expect(Lesson.fromJson(json).disciplineId, isNull);
    });

    test('Subscription: 키 없는 JSON → disciplineId null', () {
      final json = subscription().toJson()..remove('discipline_id');
      expect(Subscription.fromJson(json).disciplineId, isNull);
    });

    test('TeacherProfile: 키 없는 JSON → disciplineId null', () {
      final json = teacher().toJson()..remove('discipline_id');
      expect(TeacherProfile.fromJson(json).disciplineId, isNull);
    });
  });

  group('copyWith — disciplineId 설정/보존', () {
    test('Lesson.copyWith 으로 disciplineId 설정', () {
      expect(lesson().copyWith(disciplineId: 'music').disciplineId, 'music');
    });

    test('Subscription.copyWith 으로 disciplineId 설정', () {
      expect(
        subscription().copyWith(disciplineId: 'music').disciplineId,
        'music',
      );
    });

    test('TeacherProfile.copyWith 으로 disciplineId 설정', () {
      expect(teacher().copyWith(disciplineId: 'music').disciplineId, 'music');
    });
  });

  group('null = music 폴백 (DisciplineRegistry)', () {
    Discipline resolve(String? id) =>
        DisciplineRegistry.byId(id ?? '') ?? DisciplineRegistry.fallback;

    test('null → music (fallback)', () {
      expect(resolve(lesson().disciplineId), DisciplineRegistry.music);
    });

    test('명시 music id → music', () {
      expect(resolve('music'), DisciplineRegistry.music);
    });

    test('등록된 fitness id → fitness (#979-B)', () {
      expect(resolve('fitness'), DisciplineRegistry.fitness);
    });

    test('미등록 id → music (fallback)', () {
      expect(resolve('language'), DisciplineRegistry.music);
    });
  });
}
