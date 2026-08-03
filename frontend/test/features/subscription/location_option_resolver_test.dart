// Unit tests for #1146 — derive subscription location options from the
// teacher's profile lesson types.
//
// `allowedLocationTypes` maps the teacher's LessonTypeOption set (profile) to
// the LocationType set (subscription registration), intersected with the
// academy/private context. null/empty lessonTypes → null (no gating; keep the
// current isAcademy behavior — backward compatible for the many profiles that
// never set lessonTypes).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/location_option_resolver.dart';

void main() {
  group('allowedLocationTypes — null/empty passes through (no gating)', () {
    test('null lessonTypes → null', () {
      expect(allowedLocationTypes(null, isAcademy: false), isNull);
    });
    test('empty lessonTypes → null', () {
      expect(allowedLocationTypes(const [], isAcademy: false), isNull);
    });
  });

  group('allowedLocationTypes — private context', () {
    test(
      'inPerson → studio only (academyRoom filtered by private context)',
      () {
        expect(
          allowedLocationTypes(const [
            LessonTypeOption.inPerson,
          ], isAcademy: false),
          {LocationType.teacherStudio},
        );
      },
    );

    test('visit → student home + external place', () {
      expect(
        allowedLocationTypes(const [LessonTypeOption.visit], isAcademy: false),
        {LocationType.studentHome, LocationType.externalPlace},
      );
    });

    test('online → online', () {
      expect(
        allowedLocationTypes(const [LessonTypeOption.online], isAcademy: false),
        {LocationType.online},
      );
    });

    test('inPerson + online → studio + online', () {
      expect(
        allowedLocationTypes(const [
          LessonTypeOption.inPerson,
          LessonTypeOption.online,
        ], isAcademy: false),
        {LocationType.teacherStudio, LocationType.online},
      );
    });

    test('all three modes → all private location types', () {
      expect(
        allowedLocationTypes(const [
          LessonTypeOption.inPerson,
          LessonTypeOption.visit,
          LessonTypeOption.online,
        ], isAcademy: false),
        {
          LocationType.teacherStudio,
          LocationType.studentHome,
          LocationType.externalPlace,
          LocationType.online,
        },
      );
    });
  });

  group('allowedLocationTypes — academy context', () {
    test('inPerson → academy room (teacherStudio filtered by academy)', () {
      expect(
        allowedLocationTypes(const [
          LessonTypeOption.inPerson,
        ], isAcademy: true),
        {LocationType.academyRoom},
      );
    });

    test('visit → empty (visit modes not available in academy context)', () {
      expect(
        allowedLocationTypes(const [LessonTypeOption.visit], isAcademy: true),
        isEmpty,
      );
    });
  });
}
