// #980 — 멀티 Discipline Phase 4 검증 게이트.
//
// music 회귀 0 은 전체 스위트(all_routes_render 2뷰포트 · architecture · modal
// injection)가 증명한다. 이 파일은 그 위에 **fitness vertical 이 실제로 렌더되고
// music 과 동일한 UX 계약(C1~C8 → 분야-무관 U1~U8)을 따르는지** 를 고정한다:
//   A. fitness 셸(분야 선택 + 연습 도구 모달) 2뷰포트 렌더 스모크 (실 skeleton 패널)
//   B. U1~U8 = C1~C8 일관성 (fitness 가 music 과 같은 계약 준수)
//
// 설계: 옵시디언 "36-멀티카테고리-Discipline-플랫폼-설계" / 이슈 #980.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/domain/value_objects/expertise_catalog_registry.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/theme/expertise_color_resolver.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/screens/discipline_selection_screen.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/fitness_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools_modal.dart';

const _desktop = Size(1440, 900);
const _mobile = Size(375, 812);

/// Inert metronome/tuner stubs — fitness gates both to -1 so they are never read;
/// the overrides only keep the render off any real audio-engine platform init.
class _NoopMetronome extends Notifier<MetronomeState> implements Metronome {
  @override
  MetronomeState build() => const MetronomeState(isReady: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopTuner extends Notifier<TunerProviderState> implements Tuner {
  @override
  TunerProviderState build() => const TunerProviderState();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Emoji-presentation ranges (mirror check-ui-emoji.sh): fitness UI strings must be
// icon-free per C2 (Notebook × Score 평면 잉크 — Material Icons / NotebookGlyph only).
final _emojiRe = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{FE0F}\u{2705}\u{274C}\u{2B50}\u{2B55}\u{26A0}\u{2757}\u{2753}\u{23F0}\u{23F3}\u{2139}\u{2728}]',
  unicode: true,
);

void main() {
  // Fitness skeleton panels render EmptyStateWidget (Playfair via google_fonts);
  // keep tests offline so the async font fetch never reaches the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('#980-A fitness 셸 2뷰포트 렌더 스모크', () {
    for (final vp in const [_desktop, _mobile]) {
      final label = '@${vp.width.toInt()}';

      testWidgets('분야 선택 화면 — 음악·헬스 카드 렌더 크래시 없음 $label', (tester) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: const DisciplineSelectionScreen(role: UserRole.student),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.disciplineMusic), findsOneWidget);
        expect(find.text(AppStrings.disciplineFitness), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('연습 도구 모달 — fitness 스켈레톤 3탭·실 패널 렌더 크래시 없음 $label', (
        tester,
      ) async {
        tester.view.physicalSize = vp;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              metronomeProvider.overrideWith(() => _NoopMetronome()),
              tunerProvider.overrideWith(() => _NoopTuner()),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: PracticeToolsModal(tools: fitnessPracticeTools),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 3 탭 라벨(세트 카운터/인터벌 타이머/폼 영상) 이 좁은 375 에서도 크래시 없이.
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.tabs.length, 3);
        // 실 skeleton 패널 = EmptyStateWidget (C1). 활성 탭 패널이 렌더된다.
        expect(find.byType(EmptyStateWidget), findsWidgets);
        expect(tester.takeException(), isNull);

        // TabBarView 는 활성 페이지만 lazy layout 하므로 각 탭을 구동해
        // 탭 2·3 패널의 좁은-뷰포트 overflow 도 가드한다(리뷰 보강).
        for (final tool in fitnessPracticeTools) {
          await tester.tap(find.text(tool.displayLabel).first);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${tool.id} @${vp.width.toInt()}',
          );
        }
      });
    }
  });

  group('#980-B U1~U8 = C1~C8 일관성 — fitness 가 공통 UX 계약(C1/C2/C5/C8)을 준수한다', () {
    test('C1 — 모든 fitness 도구 패널이 EmptyStateWidget (빈/준비 상태 SSOT)', () {
      final ctx = _StubContext();
      for (final tool in fitnessPracticeTools) {
        expect(
          tool.panelBuilder(ctx, null, null),
          isA<EmptyStateWidget>(),
          reason: tool.id,
        );
      }
    });

    test('C2 — fitness UI 문자열에 이모지/픽토그램 없음 (Material/NotebookGlyph만)', () {
      final strings = <String>[
        AppStrings.disciplineFitness,
        AppStrings.practiceToolRepCounter,
        AppStrings.practiceToolIntervalTimer,
        AppStrings.practiceToolGuideMedia,
        AppStrings.practiceToolSkeletonSubtitle,
        ...ExpertiseCatalogRegistry.fitness.items,
      ];
      for (final s in strings) {
        expect(_emojiRe.hasMatch(s), isFalse, reason: s);
      }
    });

    test('C5 — fitness 도구 탭 라벨이 AppStrings 단일 상수', () {
      expect(fitnessPracticeTools.map((t) => t.displayLabel).toList(), [
        AppStrings.practiceToolRepCounter,
        AppStrings.practiceToolIntervalTimer,
        AppStrings.practiceToolGuideMedia,
      ]);
    });

    test('C8 — fitness 색상은 시맨틱 팔레트 폴백 (분야별 손코딩 색맵 없음)', () {
      final resolver = ExpertiseColorResolverRegistry.forDiscipline(
        DisciplineRegistry.fitness,
      );
      expect(resolver.catalogId, '_fallback');
      // 필라테스 같은 실 fitness 태그도 안정적으로 색을 얻는다(폴백 hash-cycle,
      // 동일 입력 = 동일 색, 크래시 없음). #980 리뷰 nit 반영.
      final a = resolver.resolve('필라테스');
      final b = resolver.resolve('필라테스');
      expect(a.background, b.background);
      expect(a.accent, b.accent);
    });
  });

  group('#980 music byte-identity 앵커 (분야 추가 후에도 음악 불변)', () {
    test('레지스트리 등록 순서 = [music, fitness, language], music 이 0번·fallback', () {
      expect(DisciplineRegistry.all.map((d) => d.id).toList(), [
        'music',
        'fitness',
        'language',
      ]);
      expect(DisciplineRegistry.fallback, DisciplineRegistry.music);
    });

    test('music 도구셋/카탈로그 불변 (22 악기, 메트로놈+튜너)', () {
      expect(ExpertiseCatalogRegistry.music.items.length, 22);
      expect(musicPracticeTools.map((t) => t.id).toList(), [
        PracticeToolIds.metronome,
        PracticeToolIds.tuner,
      ]);
    });
  });
}

/// Minimal BuildContext for building a stateless panel widget off-tree (C1 type
/// check). panelBuilder returns a const EmptyStateWidget and never reads context.
class _StubContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
