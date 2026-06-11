import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

void main() {
  Student make() => Student(
    id: 's1',
    name: '학생',
    instrument: 'violin',
    createdAt: DateTime(2026, 6, 11),
  );

  group('Student — gamification P1 nullable fields', () {
    test(
      'nickname / parentConsentAt / parentConsentRevokedAt / parentConsentToken default null',
      () {
        final s = make();
        expect(s.nickname, isNull);
        expect(s.parentConsentAt, isNull);
        expect(s.parentConsentRevokedAt, isNull);
        expect(s.parentConsentToken, isNull);
      },
    );

    test('comparisonViewEnabled defaults to false', () {
      final s = make();
      expect(s.comparisonViewEnabled, false);
    });

    test('copyWith updates only specified P1 fields', () {
      final s = make();
      final updated = s.copyWith(
        nickname: '닉',
        parentConsentAt: DateTime(2026, 6, 11, 12),
        comparisonViewEnabled: true,
      );
      expect(updated.nickname, '닉');
      expect(updated.parentConsentAt, DateTime(2026, 6, 11, 12));
      expect(updated.parentConsentRevokedAt, isNull);
      expect(updated.parentConsentToken, isNull);
      expect(updated.comparisonViewEnabled, true);
      // 기존 필드 보존
      expect(updated.id, 's1');
      expect(updated.name, '학생');
    });

    test('json round-trip preserves new P1 fields', () {
      final s = make().copyWith(
        nickname: '닉네임',
        parentConsentAt: DateTime(2026, 6, 11),
        parentConsentRevokedAt: DateTime(2026, 7, 1),
        parentConsentToken: 'tok-abc',
        comparisonViewEnabled: true,
      );
      final restored = Student.fromJson(s.toJson());
      expect(restored.nickname, '닉네임');
      expect(restored.parentConsentAt, DateTime(2026, 6, 11));
      expect(restored.parentConsentRevokedAt, DateTime(2026, 7, 1));
      expect(restored.parentConsentToken, 'tok-abc');
      expect(restored.comparisonViewEnabled, true);
    });

    test('json round-trip preserves null/default values when not set', () {
      final s = make();
      final restored = Student.fromJson(s.toJson());
      expect(restored.nickname, isNull);
      expect(restored.parentConsentAt, isNull);
      expect(restored.parentConsentRevokedAt, isNull);
      expect(restored.parentConsentToken, isNull);
      expect(restored.comparisonViewEnabled, false);
    });
  });
}
