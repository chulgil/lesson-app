import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';

void main() {
  // #962 멀티 Discipline Phase 0 — Discipline 값객체 + DisciplineRegistry SSOT.
  // #1278 음악 단일 포커스: music(0) 만 등록. enum switch 금지, id 조회 패턴은 유지
  // (미래 분야는 데이터 등록만으로 추가 가능).
  group('DisciplineRegistry', () {
    test('music(0) 만 등록되어 있다 (#1278 음악 단일 포커스)', () {
      expect(DisciplineRegistry.all.map((d) => d.id).toList(), ['music']);
      expect(DisciplineRegistry.all.first.id, 'music');
    });

    test('byId 는 등록 분야를 반환하고 미등록은 null', () {
      final music = DisciplineRegistry.byId('music');
      expect(music, isNotNull);
      expect(music!.expertiseCatalogId, 'instruments');
      expect(music.themeColorSeed, 0xFF9B1B12); // 음악 액션색(paperAccent)

      // #1278 로 제거된 분야는 더 이상 등록되지 않는다.
      expect(DisciplineRegistry.byId('fitness'), isNull);
      expect(DisciplineRegistry.byId('language'), isNull);

      // 미등록/빈 id 는 null (호출처가 fallback 으로 degrade).
      expect(DisciplineRegistry.byId('unknown_discipline'), isNull);
      expect(DisciplineRegistry.byId(''), isNull);
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
