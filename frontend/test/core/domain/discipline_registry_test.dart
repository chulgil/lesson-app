import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';

void main() {
  // #962 멀티 Discipline Phase 0 — Discipline 값객체 + DisciplineRegistry SSOT.
  // music 만 등록 = 현행 동작 변경 0. enum switch 금지, id 조회 패턴.
  group('DisciplineRegistry', () {
    test('music 가 0번 인스턴스로 등록되어 있다', () {
      expect(DisciplineRegistry.all, isNotEmpty);
      expect(DisciplineRegistry.all.first.id, 'music');
      // music 만 등록 — 추가 분야는 데이터 등록만으로 확장(코드 변경 0).
      expect(DisciplineRegistry.all.length, 1);
    });

    test('byId 는 등록 분야를 반환하고 미등록은 null', () {
      final music = DisciplineRegistry.byId('music');
      expect(music, isNotNull);
      expect(music!.expertiseCatalogId, 'instruments');
      expect(music.themeColorSeed, 0xFF9B1B12); // 음악 액션색(paperAccent)
      expect(DisciplineRegistry.byId('fitness'), isNull);
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
