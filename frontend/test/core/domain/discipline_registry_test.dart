import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';

void main() {
  // #962 멀티 Discipline Phase 0 — Discipline 값객체 + DisciplineRegistry SSOT.
  // music(0) + fitness(1) 등록(#979-B). enum switch 금지, id 조회 패턴.
  group('DisciplineRegistry', () {
    test('music(0) + fitness(1) 이 등록 순서대로 있다 (#979-B)', () {
      expect(DisciplineRegistry.all, isNotEmpty);
      expect(DisciplineRegistry.all.first.id, 'music');
      // Phase 4 (#979-B) 에서 fitness 를 데이터 등록만으로 추가(코드 변경 0).
      expect(DisciplineRegistry.all.map((d) => d.id).toList(), [
        'music',
        'fitness',
      ]);
    });

    test('byId 는 등록 분야를 반환하고 미등록은 null', () {
      final music = DisciplineRegistry.byId('music');
      expect(music, isNotNull);
      expect(music!.expertiseCatalogId, 'instruments');
      expect(music.themeColorSeed, 0xFF9B1B12); // 음악 액션색(paperAccent)

      final fitness = DisciplineRegistry.byId('fitness');
      expect(fitness, isNotNull);
      expect(fitness!.expertiseCatalogId, 'specialties'); // #979-B

      // 미등록/빈 id 는 null (호출처가 fallback 으로 degrade).
      expect(DisciplineRegistry.byId('language'), isNull);
      expect(DisciplineRegistry.byId(''), isNull);
    });

    test('fitness 는 specialties 카탈로그를 가리킨다 (#979-B)', () {
      expect(DisciplineRegistry.fitness.id, 'fitness');
      expect(DisciplineRegistry.fitness.displayKey, 'discipline.fitness');
      expect(DisciplineRegistry.fitness.expertiseCatalogId, 'specialties');
    });

    test('fallback 은 music — null/legacy disciplineId 폴백', () {
      expect(DisciplineRegistry.fallback.id, 'music');
      // 미등록/null 조회 시 호출처가 fallback 으로 안전 degrade
      expect(
        DisciplineRegistry.byId('unknown') ?? DisciplineRegistry.fallback,
        DisciplineRegistry.music,
      );
    });

    test('Discipline 은 값 동등성(value equality)을 가진다', () {
      const a = Discipline(
        id: 'music',
        displayKey: 'discipline.music',
        themeColorSeed: 0xFF9B1B12,
        expertiseCatalogId: 'instruments',
      );
      const b = Discipline(
        id: 'music',
        displayKey: 'discipline.music',
        themeColorSeed: 0xFF9B1B12,
        expertiseCatalogId: 'instruments',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, DisciplineRegistry.music);
    });
  });
}
