// #1102 — 멀티 Discipline Phase 5 검증 게이트 (어학 vertical).
//
// music·fitness 회귀 0 은 전체 스위트(all_routes_render · architecture · modal
// injection)가 증명한다. 이 파일은 그 위에 **language vertical 이 실제로 렌더되고
// music/fitness 와 동일한 UX 계약(C1~C8)을 따르는지** 를 고정한다:
//   A. language 셸(분야 선택 + 연습 도구 모달) 2뷰포트 렌더 스모크 (실 skeleton 패널)
//   B. C1~C8 일관성 (language 가 공통 계약 준수)
//
// #979-B/#980 fitness 게이트의 정확한 미러. 설계: 이슈 #1102.
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
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/language_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/music_practice_tools.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools_modal.dart';
import 'package:lessonaza/features/vocabulary/domain/repositories/vocab_repository.dart';
import 'package:lessonaza/features/vocabulary/presentation/providers/vocab_repository_provider.dart';
import 'package:lessonaza/features/vocabulary/presentation/widgets/vocab_book_panel.dart';

const _desktop = Size(1440, 900);
const _mobile = Size(375, 812);

/// Inert metronome/tuner stubs — language gates both to -1 so they are never
/// read; the overrides only keep the render off any real audio-engine init.
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

// Emoji-presentation ranges (mirror check-ui-emoji.sh): language UI strings must
// be icon-free per C2 (Material Icons / NotebookGlyph only).
final _emojiRe = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{FE0F}\u{2705}\u{274C}\u{2B50}\u{2B55}\u{26A0}\u{2757}\u{2753}\u{23F0}\u{23F3}\u{2139}\u{2728}]',
  unicode: true,
);

void main() {
  // Language skeleton panels render EmptyStateWidget (Playfair via google_fonts);
  // keep tests offline so the async font fetch never reaches the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('#1102-A language 셸 2뷰포트 렌더 스모크', () {
    for (final vp in const [_desktop, _mobile]) {
      final label = '@${vp.width.toInt()}';

      testWidgets('분야 선택 화면 — 음악·헬스·어학 카드 렌더 크래시 없음 $label', (tester) async {
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
        expect(find.text(AppStrings.disciplineLanguage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('연습 도구 모달 — language 스켈레톤 4탭·실 패널 렌더 크래시 없음 $label', (
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
              // #1124: 단어장 패널은 실 store 를 읽는다 — 결정적 렌더를 위해 빈
              // store 로 오버라이드(실 Hive I/O 는 fake-async 에서 완료 안 됨).
              vocabRepositoryProvider.overrideWithValue(
                _UnavailableVocabRepository(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: PracticeToolsModal(tools: languagePracticeTools),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 4 탭 라벨(단어장/받아쓰기/발음/회화) 이 좁은 375 에서도 크래시 없이.
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.tabs.length, 4);
        // 활성 탭 = 단어장(#1124 첫 실 도구) → VocabBookPanel. 나머지 3개는 skeleton.
        expect(find.byType(VocabBookPanel), findsOneWidget);
        expect(tester.takeException(), isNull);

        // TabBarView 는 활성 페이지만 lazy layout 하므로 각 탭을 구동해
        // 탭 2·3·4 패널의 좁은-뷰포트 overflow 도 가드한다.
        for (final tool in languagePracticeTools) {
          await tester.tap(find.text(tool.displayLabel).first);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${tool.id} @${vp.width.toInt()}',
          );
        }

        // skeleton 탭(받아쓰기/발음/회화)은 여전히 EmptyStateWidget (C1).
        expect(find.byType(EmptyStateWidget), findsWidgets);
      });
    }
  });

  group('#1102-B C1~C8 일관성 — language 가 공통 UX 계약(C1/C2/C5/C8)을 준수한다', () {
    test('C1 — 준비 중 language 도구는 EmptyStateWidget; 단어장은 실 패널(#1124)', () {
      final ctx = _StubContext();
      for (final tool in languagePracticeTools) {
        final panel = tool.panelBuilder(ctx, null, null);
        if (tool.id == LanguagePracticeToolIds.vocabBook) {
          // 첫 실 language 도구 — 준비 상태 SSOT(EmptyStateWidget)를 벗어난다.
          expect(panel, isA<VocabBookPanel>(), reason: tool.id);
        } else {
          expect(panel, isA<EmptyStateWidget>(), reason: tool.id);
        }
      }
    });

    test('C2 — language UI 문자열에 이모지/픽토그램 없음 (Material/NotebookGlyph만)', () {
      final strings = <String>[
        AppStrings.disciplineLanguage,
        AppStrings.practiceToolVocabBook,
        AppStrings.practiceToolDictation,
        AppStrings.practiceToolPronunciation,
        AppStrings.practiceToolConversation,
        AppStrings.practiceToolSkeletonSubtitle,
        ...ExpertiseCatalogRegistry.language.items,
      ];
      for (final s in strings) {
        expect(_emojiRe.hasMatch(s), isFalse, reason: s);
      }
    });

    test('C5 — language 도구 탭 라벨이 AppStrings 단일 상수', () {
      expect(languagePracticeTools.map((t) => t.displayLabel).toList(), [
        AppStrings.practiceToolVocabBook,
        AppStrings.practiceToolDictation,
        AppStrings.practiceToolPronunciation,
        AppStrings.practiceToolConversation,
      ]);
    });

    test('C8 — language 색상은 시맨틱 팔레트 폴백 (분야별 손코딩 색맵 없음)', () {
      final resolver = ExpertiseColorResolverRegistry.forDiscipline(
        DisciplineRegistry.language,
      );
      expect(resolver.catalogId, '_fallback');
      // 영어 같은 실 language 태그도 안정적으로 색을 얻는다(폴백 hash-cycle,
      // 동일 입력 = 동일 색, 크래시 없음).
      final a = resolver.resolve('영어');
      final b = resolver.resolve('영어');
      expect(a.background, b.background);
      expect(a.accent, b.accent);
    });
  });

  group('#1102 music/fitness byte-identity 앵커 (분야 추가 후에도 불변)', () {
    test('레지스트리 등록 순서 = [music, fitness, language], music 이 0번·fallback', () {
      expect(DisciplineRegistry.all.map((d) => d.id).toList(), [
        'music',
        'fitness',
        'language',
      ]);
      expect(DisciplineRegistry.fallback, DisciplineRegistry.music);
    });

    test('language 카탈로그/도구 = subjects 3종, 메트로놈·튜너 없음', () {
      expect(ExpertiseCatalogRegistry.language.items, ['영어', '중국어', '일본어']);
      final ids = languagePracticeTools.map((t) => t.id).toSet();
      expect(ids.contains(PracticeToolIds.metronome), isFalse);
      expect(ids.contains(PracticeToolIds.tuner), isFalse);
    });
  });
}

/// Minimal BuildContext for building a stateless panel widget off-tree (C1 type
/// check). panelBuilder just constructs the widget and never reads context.
class _StubContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A [VocabRepository] whose calls throw — the 단어장 panel then hits its error
/// fallback ("nothing due") deterministically, with no real Hive I/O (#1124).
class _UnavailableVocabRepository implements VocabRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('vocab store unavailable in gate test');
}
