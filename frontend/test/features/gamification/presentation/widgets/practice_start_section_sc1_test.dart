import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_section.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';

import '../../../../test_helper.dart';

/// 학생 게이미피케이션 P1 — Job 7 PR-C 통합 검증.
/// 스펙 §SC-1: 홈 첫 탭 후 5초 안에 연습(메트로놈) 시작 가능.
///
/// 본 widget test 는 [PracticeStartSection.onStartTap] 이 호출됐을 때
/// [PracticeToolsModal] 의 BottomSheet route 가 push 되기까지의 wall-clock
/// 을 Stopwatch 로 측정한다. 실 device 의 음향/권한 흐름은 본 테스트의
/// 검증 범위 밖 — 수동 회귀 또는 후속 integration_test 가 다룬다.

class _NoopMetronome extends Notifier<MetronomeState> implements Metronome {
  @override
  MetronomeState build() => const MetronomeState(isReady: true);

  @override
  Future<void> warmUp() async {}

  @override
  void start() {}

  @override
  void stop({
    String? studentId,
    int? practiceMinutesElapsed,
    String? sectionId,
  }) {}

  @override
  void toggle() {}

  @override
  Future<void> setBpm(int bpm) async {}

  @override
  Future<void> incrementBpm(int delta) async {}

  @override
  Future<void> setTimeSignature(TimeSignature timeSignature) async {}

  @override
  Future<void> setSound(MetronomeSound sound) async {}

  @override
  void toggleVisualFlash() {}

  @override
  void toggleVibration() {}

  @override
  Future<void> setAccentPattern(AccentPattern pattern) async {}

  @override
  Future<void> updateSettings(MetronomeSettings settings) async {}

  @override
  Future<void> playTapSound() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopTuner extends Notifier<TunerProviderState> implements Tuner {
  @override
  TunerProviderState build() => const TunerProviderState();

  @override
  Future<void> stopCompletely() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  testWidgets('SC-1 — 홈 첫 탭 후 5초 안에 PracticeToolsModal 표시', (tester) async {
    final mockStudent = Student(
      id: 's1',
      name: '민지',
      instrument: 'piano',
      nickname: '민지짱',
      createdAt: DateTime(2026, 1, 1),
    );
    const mockHeatmap = GrowthHeatmap(studentId: 's1', days: {});
    final observer = _SpyNavigatorObserver();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentProvider('s1').overrideWith((ref) async => mockStudent),
          growthHeatmapProvider('s1').overrideWith((ref) async => mockHeatmap),
          metronomeProvider.overrideWith(() => _NoopMetronome()),
          tunerProvider.overrideWith(() => _NoopTuner()),
        ],
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: PracticeStartSection(studentId: 's1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('practice_start_button')), findsOneWidget);

    final initialPushCount = observer.pushed.length;
    final stopwatch = Stopwatch()..start();
    await tester.tap(find.byKey(const ValueKey('practice_start_button')));
    // BottomSheet 가 push 되는 frame 까지 한 번만 pump (animations skip).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    stopwatch.stop();

    // PracticeToolsModal 의 ModalBottomSheetRoute 가 추가됐는가?
    expect(
      observer.pushed.length,
      greaterThan(initialPushCount),
      reason: 'PracticeToolsModal.show 가 호출돼 route 가 push 되어야 함',
    );
    // SC-1 게이트: 5초 안에 modal 표시
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(5000),
      reason: 'SC-1: 홈 첫 탭부터 modal 표시까지 < 5000ms',
    );

    // Cleanup: ProviderScope 가 살아있는 동안 명시적으로 modal pop —
    // PracticeToolsModalState.dispose 가 ref.read(tunerProvider.notifier) 호출하므로.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();
  });
}
