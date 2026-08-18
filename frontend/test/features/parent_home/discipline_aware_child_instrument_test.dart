import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/domain/value_objects/discipline.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show activeDisciplineProvider;
import 'package:lessonaza/features/auth/presentation/providers/active_discipline_provider.dart'
    show SelectedDisciplineStorage, selectedDisciplineStorageProvider;
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/extensions/parent_home_domain_visuals.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/child_profile_form_screen.dart';

/// #1072 잔여 — parent child_profile 악기 picker discipline-aware.
///
/// child_profile 은 다른 picker 와 달리 **영문 키 저장**(`'violin'`) + 아이콘 맵
/// 구조라, music 은 기존 5-키 큐레이션을 유지(byte-identical)하고 non-music 분야만
/// `ExpertiseCatalogRegistry.forDiscipline` 라벨을 노출한다. 저장값이 활성
/// 카탈로그 밖이면 items 에 prepend 해 DropdownButton value 계약을 지킨다(#1098 미러).
///
/// #1278 (음악 단일 포커스): 등록 분야가 music 뿐이므로 non-music 경로는 미등록
/// 분야로 구동한다 — 카탈로그가 music 으로 degrade 하되 키=라벨 분기는 유지된다.
/// Resolves late, reproducing the cold-start where activeDisciplineProvider
/// first emits the music fallback (storage AsyncLoading) then the resolved
/// discipline — the path a synchronous override masks (adversarial-review gap).
class _AsyncLegacyStorage extends SelectedDisciplineStorage {
  @override
  Future<String?> build() async => 'fitness'; // #1278 로 제거된 legacy 저장값
}

void main() {
  // #980: keep Playfair (google_fonts) offline so Notebook surfaces render in
  // widget tests without a late network fetch dangling past teardown.
  GoogleFonts.config.allowRuntimeFetching = false;

  const musicOnlyLabel = '바이올린'; // music 카탈로그 전용
  const unregisteredTag = '필라테스'; // 등록 카탈로그에 없는 태그 (#1278)
  const musicKey = 'violin'; // child_profile 이 저장하는 영문 키

  /// 미등록 분야 — 카탈로그는 music 으로 degrade 하지만 non-music 분기를 탄다.
  const unregisteredDiscipline = Discipline(
    id: 'unregistered',
    displayKey: 'discipline.unregistered',
    themeColorSeed: 0xFF000000,
    expertiseCatalogId: 'specialties',
  );

  ChildProfile childWith(String instrument) => ChildProfile(
    id: 'c1',
    parentId: 'p1',
    name: '아이',
    birthYear: 2018,
    instrument: instrument,
    level: 'beginner',
    profileColorKey: 'profileBlue',
    createdAt: DateTime.utc(2026, 1, 1),
  );

  Future<void> pump(
    WidgetTester tester,
    Discipline d, {
    ChildProfile? existing,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activeDisciplineProvider.overrideWith((ref) => d)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ChildProfileFormScreen(
            parentId: 'p1',
            existingProfile: existing,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Both instrument and level are DropdownButton<String>; the level dropdown is
  // the one that lists 'elementary', so the instrument dropdown is the other.
  List<DropdownButton<String>> stringDropdowns(WidgetTester tester) =>
      tester
          .widgetList<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .toList();

  DropdownButton<String> instrumentDropdown(WidgetTester tester) =>
      stringDropdowns(tester).firstWhere(
        (d) => !d.items!.any((i) => i.value == 'elementary'),
        orElse:
            () => throw TestFailure(
              'instrument DropdownButton<String> not found (level '
              'disambiguation by "elementary" failed)',
            ),
      );

  group('pure childInstrumentOptionsFor', () {
    test('music: 기존 5-키 (byte-identical, 영문 키)', () {
      final opts = childInstrumentOptionsFor(DisciplineRegistry.music);
      expect(opts.map((o) => o.$1).toList(), kChildInstrumentKeys);
      expect(opts.first.$1, musicKey);
      expect(opts.map((o) => o.$2), contains(musicOnlyLabel));
      expect(opts.map((o) => o.$2), isNot(contains(unregisteredTag)));
    });

    test('미등록 분야: 카탈로그를 키=라벨로 (music degrade) — #1278', () {
      final opts = childInstrumentOptionsFor(unregisteredDiscipline);
      // 카탈로그는 music 으로 degrade 하되, non-music 분기라 영문 키가 아니라
      // 카탈로그 라벨 자체가 키가 된다.
      expect(opts.map((o) => o.$1), contains(musicOnlyLabel));
      expect(opts.map((o) => o.$1), isNot(contains(unregisteredTag)));
      // 키=라벨 (영문 키 아님)
      for (final o in opts) {
        expect(o.$1, o.$2);
      }
      expect(opts.map((o) => o.$1), isNot(contains(musicKey)));
    });
  });

  group('ChildProfileFormScreen 드롭다운', () {
    testWidgets('music 신규: 기본값 violin, 악기 라벨 노출 — byte-identity 앵커', (
      tester,
    ) async {
      await pump(tester, DisciplineRegistry.music);
      final d = instrumentDropdown(tester);
      expect(d.value, musicKey);
      final values = d.items!.map((e) => e.value).toList();
      expect(values, containsAll(kChildInstrumentKeys));
      expect(values, isNot(contains(unregisteredTag)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('미등록 분야 신규: 기본값=카탈로그 첫 항목, violin 키 부재 — #1278', (
      tester,
    ) async {
      await pump(tester, unregisteredDiscipline);
      final d = instrumentDropdown(tester);
      final values = d.items!.map((e) => e.value).toList();
      expect(values, contains(musicOnlyLabel));
      expect(values, isNot(contains(musicKey)));
      expect(d.value, musicOnlyLabel); // degrade 한 카탈로그의 첫 옵션 — 구체 단언
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'value-preservation: violin 자녀를 미등록 분야 활성 중 편집해도 violin 보존',
      (tester) async {
        await pump(
          tester,
          unregisteredDiscipline,
          existing: childWith(musicKey),
        );
        final d = instrumentDropdown(tester);
        expect(d.value, musicKey); // revert/assert 없이 보존
        final values = d.items!.map((e) => e.value).toList();
        expect(values, contains(musicKey)); // prepend
        expect(values, contains(musicOnlyLabel)); // + 카탈로그 옵션
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'cold-start: legacy fitness 저장값이 늦게 resolve 돼도 music 기본값(violin) 유지 — #1278',
      (tester) async {
        // No synchronous activeDisciplineProvider override — let the async
        // storage resolve after a frame. #1278 이후 legacy 'fitness' 저장값은
        // music 으로 degrade 하므로, 재파생 후에도 기본값은 violin 이어야 한다.
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedDisciplineStorageProvider.overrideWith(
                () => _AsyncLegacyStorage(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const ChildProfileFormScreen(parentId: 'p1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final d = instrumentDropdown(tester);
        expect(d.value, musicKey); // legacy id → music degrade → violin 기본값
        expect(
          d.items!.map((e) => e.value),
          containsAll(kChildInstrumentKeys),
        ); // music 5-키 큐레이션
        expect(tester.takeException(), isNull);
      },
    );
  });
}
