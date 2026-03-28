import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // Helper
  // ═══════════════════════════════════════════════════════════════════════════

  TeacherSettings createSettings({
    Map<String, Map<String, int>>? priceTable,
    bool trialFree = false,
  }) {
    return TeacherSettings(
      id: 'teacher_1',
      instruments: ['바이올린', '피아노'],
      createdAt: DateTime(2026, 1, 1),
      lessonPriceTable: priceTable,
      trialLessonFree: trialFree,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getPrice tests (existing method)
  // ═══════════════════════════════════════════════════════════════════════════

  group('getPrice', () {
    test('정상 조회 — 바이올린 beginner → 40000', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000, 'intermediate': 50000, 'advanced': 70000},
          '피아노': {'beginner': 35000, 'intermediate': 45000, 'advanced': 60000},
        },
      );
      expect(settings.getPrice('바이올린', 'beginner'), 40000);
    });

    test('없는 악기 → null', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000},
        },
      );
      expect(settings.getPrice('첼로', 'beginner'), isNull);
    });

    test('없는 레벨 → null', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000},
        },
      );
      expect(settings.getPrice('바이올린', 'advanced'), isNull);
    });

    test('테이블 null → null', () {
      final settings = createSettings(priceTable: null);
      expect(settings.getPrice('바이올린', 'beginner'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // getPriceByExperience tests (new method — uses enum)
  // ═══════════════════════════════════════════════════════════════════════════

  group('getPriceByExperience', () {
    test('beginner enum → beginner 키 매핑', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000, 'intermediate': 50000, 'advanced': 70000},
        },
      );
      expect(
        settings.getPriceByExperience('바이올린', UnifiedExperienceLevel.beginner),
        40000,
      );
    });

    test('intermediate enum → intermediate 키 매핑', () {
      final settings = createSettings(
        priceTable: {
          '피아노': {'beginner': 35000, 'intermediate': 45000, 'advanced': 60000},
        },
      );
      expect(
        settings.getPriceByExperience('피아노', UnifiedExperienceLevel.intermediate),
        45000,
      );
    });

    test('advanced enum → advanced 키 매핑', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000, 'intermediate': 50000, 'advanced': 70000},
        },
      );
      expect(
        settings.getPriceByExperience('바이올린', UnifiedExperienceLevel.advanced),
        70000,
      );
    });

    test('테이블 null → null', () {
      final settings = createSettings(priceTable: null);
      expect(
        settings.getPriceByExperience('바이올린', UnifiedExperienceLevel.beginner),
        isNull,
      );
    });

    test('악기 미등록 → null', () {
      final settings = createSettings(
        priceTable: {
          '바이올린': {'beginner': 40000},
        },
      );
      expect(
        settings.getPriceByExperience('첼로', UnifiedExperienceLevel.beginner),
        isNull,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // trialLessonFree tests
  // ═══════════════════════════════════════════════════════════════════════════

  group('trialLessonFree', () {
    test('기본값 false', () {
      final settings = createSettings();
      expect(settings.trialLessonFree, isFalse);
    });

    test('true 설정', () {
      final settings = createSettings(trialFree: true);
      expect(settings.trialLessonFree, isTrue);
    });
  });
}
