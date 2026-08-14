import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_preferences.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification_type_group.dart';

void main() {
  group('NotificationPreferences.groupOverrides serialization (#1272)', () {
    test('defaults() has an empty groupOverrides map', () {
      expect(NotificationPreferences.defaults.groupOverrides, isEmpty);
    });

    test('fromJson tolerates a payload with no groupOverrides key — '
        'pre-#1272 persisted JSON decodes to an empty map, not a crash', () {
      final prefs = NotificationPreferences.fromJson(const {
        'masterEnabled': true,
        'lessonEnabled': true,
      });
      expect(prefs.groupOverrides, isEmpty);
    });

    test('toJson/fromJson round trip preserves group overrides', () {
      const prefs = NotificationPreferences(
        groupOverrides: {
          NotificationTypeGroup.streakAndGoal: false,
          NotificationTypeGroup.lessonStarting: true,
        },
      );
      final decoded = NotificationPreferences.fromJson(prefs.toJson());
      expect(decoded.groupOverrides, prefs.groupOverrides);
      expect(decoded, prefs);
    });

    test('fromJson drops unknown group names instead of throwing', () {
      final prefs = NotificationPreferences.fromJson(const {
        'groupOverrides': {
          'streakAndGoal': false,
          'someRemovedFutureGroup': true,
        },
      });
      expect(prefs.groupOverrides, {
        NotificationTypeGroup.streakAndGoal: false,
      });
    });

    test('fromJson ignores non-bool values for a known group', () {
      final prefs = NotificationPreferences.fromJson(const {
        'groupOverrides': {'streakAndGoal': 'not-a-bool'},
      });
      expect(prefs.groupOverrides, isEmpty);
    });
  });

  group('NotificationPreferences.copyWith — groupOverrides', () {
    test('omitted groupOverrides keeps the existing map', () {
      const prefs = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
      );
      final updated = prefs.copyWith(masterEnabled: false);
      expect(updated.groupOverrides, prefs.groupOverrides);
    });

    test('provided groupOverrides replaces the map wholesale', () {
      const prefs = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
      );
      final updated = prefs.copyWith(
        groupOverrides: const {NotificationTypeGroup.lessonStarting: true},
      );
      expect(updated.groupOverrides, {
        NotificationTypeGroup.lessonStarting: true,
      });
    });
  });

  group('NotificationPreferences equality — groupOverrides', () {
    test('equal maps with different identity are still equal', () {
      const a = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
      );
      const b = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
      );
      expect(a, b);
    });

    test('different group override values are not equal', () {
      const a = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: false},
      );
      const b = NotificationPreferences(
        groupOverrides: {NotificationTypeGroup.streakAndGoal: true},
      );
      expect(a == b, isFalse);
    });
  });
}
