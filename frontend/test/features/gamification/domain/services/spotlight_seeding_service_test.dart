import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_spotlight_prompt_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';
import 'package:lessonaza/features/gamification/domain/services/spotlight_seeding_service.dart';

void main() {
  final now = DateTime.utc(2026, 6, 12);

  late MockSpotlightPromptRepository repo;
  late SpotlightSeedingService svc;

  setUp(() {
    repo = MockSpotlightPromptRepository();
    svc = SpotlightSeedingService(repo);
  });

  group('seedTeacherRecommendation', () {
    test('시드 성공 + listForStudent 에 noted', () async {
      final ok = await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_001',
        title: '바이올린 비브라토',
        videoId: 'vid_001',
        ctaRoute: '/practice/youtube',
        now: now,
      );
      expect(ok, isTrue);

      final list = await repo.listForStudent('s1');
      expect(list, hasLength(1));
      expect(list.first.id, 'teacher_rec:tr_001');
      expect(list.first.type, SpotlightType.teacherRec);
      expect(list.first.videoId, 'vid_001');
      expect(list.first.ctaRoute, '/practice/youtube');
      expect(list.first.isMandatory, isFalse);
    });

    test('isMandatory=true 전달 시 priority +10 진입 (priority=0)', () async {
      await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_must',
        title: '필수 추천',
        now: now,
        isMandatory: true,
      );
      final p = (await repo.listForStudent('s1')).first;
      expect(p.isMandatory, isTrue);
      expect(p.priority, 0);
    });

    test('같은 teacher_resource 재시드 → skip (false)', () async {
      await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_001',
        title: 'A',
        now: now,
      );
      final second = await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_001',
        title: 'A-revised',
        now: now.add(const Duration(hours: 1)),
      );
      expect(second, isFalse);
      final list = await repo.listForStudent('s1');
      expect(list, hasLength(1));
      expect(list.first.title, 'A', reason: '재시드는 덮어쓰지 않음');
    });

    test('다른 teacher_resource → 별도 시드', () async {
      await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_a',
        title: 'A',
        now: now,
      );
      await svc.seedTeacherRecommendation(
        studentId: 's1',
        teacherResourceId: 'tr_b',
        title: 'B',
        now: now,
      );
      expect(await repo.listForStudent('s1'), hasLength(2));
    });
  });

  group('seedSeasonEvent', () {
    test('시드 성공', () async {
      final ok = await svc.seedSeasonEvent(
        studentId: 's1',
        seasonKey: '어린이날2027',
        title: '어린이날 합주 챌린지',
        now: now,
      );
      expect(ok, isTrue);
      final p = (await repo.listForStudent('s1')).first;
      expect(p.id, 'season:어린이날2027');
      expect(p.type, SpotlightType.seasonEvent);
    });

    test('같은 seasonKey 재시드 → skip', () async {
      await svc.seedSeasonEvent(
        studentId: 's1',
        seasonKey: '추석2026',
        title: '추석',
        now: now,
      );
      final second = await svc.seedSeasonEvent(
        studentId: 's1',
        seasonKey: '추석2026',
        title: '추석-수정',
        now: now,
      );
      expect(second, isFalse);
      expect(await repo.listForStudent('s1'), hasLength(1));
    });

    test('다른 seasonKey → 별도 시드', () async {
      await svc.seedSeasonEvent(
        studentId: 's1',
        seasonKey: '추석2026',
        title: '추석',
        now: now,
      );
      await svc.seedSeasonEvent(
        studentId: 's1',
        seasonKey: '크리스마스2026',
        title: '크리스마스',
        now: now,
      );
      expect(await repo.listForStudent('s1'), hasLength(2));
    });
  });

  group('seedRoutineSuggestion', () {
    test('recentStreakDays < 30 → skip', () async {
      for (final days in [0, 1, 29]) {
        final ok = await svc.seedRoutineSuggestion(
          studentId: 's1',
          recentStreakDays: days,
          now: now,
        );
        expect(ok, isFalse);
      }
      expect(await repo.listForStudent('s1'), isEmpty);
    });

    test('recentStreakDays == 30 → 시드 성공', () async {
      final ok = await svc.seedRoutineSuggestion(
        studentId: 's1',
        recentStreakDays: 30,
        now: now,
      );
      expect(ok, isTrue);
      final p = (await repo.listForStudent('s1')).first;
      expect(p.type, SpotlightType.routineSuggestion);
      expect(p.id, 'routine:s1');
    });

    test('학생당 1개 — 재시드 시 skip', () async {
      await svc.seedRoutineSuggestion(
        studentId: 's1',
        recentStreakDays: 30,
        now: now,
      );
      final second = await svc.seedRoutineSuggestion(
        studentId: 's1',
        recentStreakDays: 100,
        now: now,
      );
      expect(second, isFalse);
      expect(await repo.listForStudent('s1'), hasLength(1));
    });

    test('다른 학생은 별도 routine 시드 가능', () async {
      await svc.seedRoutineSuggestion(
        studentId: 's1',
        recentStreakDays: 30,
        now: now,
      );
      await svc.seedRoutineSuggestion(
        studentId: 's2',
        recentStreakDays: 30,
        now: now,
      );
      expect(await repo.listForStudent('s1'), hasLength(1));
      expect(await repo.listForStudent('s2'), hasLength(1));
    });
  });

  group('상수 / id 생성기', () {
    test('routineSuggestionMinStreakDays = 30', () {
      expect(SpotlightSeedingService.routineSuggestionMinStreakDays, 30);
    });

    test('id deterministic', () {
      expect(
        SpotlightSeedingService.teacherRecId('tr_001'),
        'teacher_rec:tr_001',
      );
      expect(SpotlightSeedingService.seasonEventId('추석2026'), 'season:추석2026');
      expect(SpotlightSeedingService.routineSuggestionId('s1'), 'routine:s1');
    });
  });
}
