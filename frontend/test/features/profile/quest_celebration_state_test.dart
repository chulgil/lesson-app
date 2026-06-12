// Task 5.3 — `QuestCelebrationState.visible` / `graduated` 정합성.
//
// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §8.2 / §9.4

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/constants/durations.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_celebration_provider.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 6, 12, 12);

  group('QuestCelebrationState — visible (졸업 카드 노출 규칙)', () {
    test('celebratedAt == null → visible == false (아직 졸업 아님)', () {
      final state = QuestCelebrationState(
        celebratedAt: null,
        dismissedAt: null,
        now: fixedNow,
      );
      expect(state.visible, false);
      expect(state.graduated, false);
    });

    test('celebratedAt == 방금 + dismissedAt == null → visible == true', () {
      final state = QuestCelebrationState(
        celebratedAt: fixedNow.subtract(const Duration(hours: 1)),
        dismissedAt: null,
        now: fixedNow,
      );
      expect(state.visible, true);
      expect(state.graduated, false);
    });

    test('celebratedAt 후 6일 경과 → visible == true (grace 내)', () {
      final state = QuestCelebrationState(
        celebratedAt: fixedNow.subtract(const Duration(days: 6)),
        dismissedAt: null,
        now: fixedNow,
      );
      expect(state.visible, true);
      expect(state.graduated, false);
    });

    test(
      'celebratedAt 후 7일 + 1시간 경과 → visible == false (grace 만료) — Task 5.3 spec test',
      () {
        final state = QuestCelebrationState(
          celebratedAt: fixedNow.subtract(
            kQuestGraduationGrace + const Duration(hours: 1),
          ),
          dismissedAt: null,
          now: fixedNow,
        );
        expect(state.visible, false);
        expect(state.graduated, true);
      },
    );

    test('celebratedAt 후 정확히 7일 경과 → visible == false (경계값)', () {
      final state = QuestCelebrationState(
        celebratedAt: fixedNow.subtract(kQuestGraduationGrace),
        dismissedAt: null,
        now: fixedNow,
      );
      expect(state.visible, false);
      expect(state.graduated, true);
    });
  });

  group('QuestCelebrationState — graduated (메인 hide 규칙)', () {
    test('celebratedAt != null + dismissedAt != null → graduated == true', () {
      final state = QuestCelebrationState(
        celebratedAt: fixedNow.subtract(const Duration(hours: 1)),
        dismissedAt: fixedNow.subtract(const Duration(minutes: 30)),
        now: fixedNow,
      );
      expect(state.visible, false);
      expect(state.graduated, true);
    });

    test('celebratedAt == null + dismissedAt 무관 → graduated == false', () {
      final state = QuestCelebrationState(
        celebratedAt: null,
        dismissedAt: fixedNow,
        now: fixedNow,
      );
      expect(state.graduated, false);
    });
  });

  group('kQuestGraduationGrace 상수 — spec §9.4', () {
    test('정확히 7일', () {
      expect(kQuestGraduationGrace, const Duration(days: 7));
    });
  });
}
