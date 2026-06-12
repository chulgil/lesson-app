import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/presentation/providers/metronome_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/practice_tools/metronome_panel.dart';

import '../../../../../test_helper.dart';

/// Stateful mock metronome — start/stop 호출 시 [isPlaying] 토글 +
/// stop 호출 인자 캡처. 학생 게이미피케이션 P1 Job 7 PR-A 검증용.
class _StatefulMockMetronome extends Notifier<MetronomeState>
    implements Metronome {
  bool stopCalled = false;
  String? capturedStudentId;
  int? capturedMinutes;

  @override
  MetronomeState build() => const MetronomeState(isReady: true);

  @override
  Future<void> warmUp() async {}

  @override
  void start() {
    state = state.copyWith(isPlaying: true);
  }

  @override
  void stop({String? studentId, int? practiceMinutesElapsed}) {
    state = state.copyWith(isPlaying: false);
    stopCalled = true;
    capturedStudentId = studentId;
    capturedMinutes = practiceMinutesElapsed;
  }

  @override
  void toggle() {
    if (state.isPlaying) {
      stop();
    } else {
      start();
    }
  }

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

Future<_StatefulMockMetronome> _pumpPanel(
  WidgetTester tester, {
  String? studentId,
}) async {
  final mock = _StatefulMockMetronome();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [metronomeProvider.overrideWith(() => mock)],
      child: MaterialApp(
        home: Scaffold(body: MetronomePanel(studentId: studentId)),
      ),
    ),
  );
  await tester.pump();
  return mock;
}

void main() {
  setUpAll(() async {
    await initializeTestEnvironment();
  });

  tearDownAll(() async {
    await cleanupTestEnvironment();
  });

  testWidgets('studentId 없이 호출되면 stop 시 logger 인자 미전달 (back-compat)', (
    tester,
  ) async {
    final mock = await _pumpPanel(tester);
    final playPause = find.byKey(const ValueKey('metronome_play_pause_button'));

    // Start
    await tester.tap(playPause);
    await tester.pump();
    // Stop
    await tester.tap(playPause);
    await tester.pump();

    expect(mock.stopCalled, isTrue);
    expect(mock.capturedStudentId, isNull);
    expect(mock.capturedMinutes, isNull);
  });

  testWidgets('studentId 주입 시 stop 인자에 studentId + practiceMinutesElapsed 전달', (
    tester,
  ) async {
    final mock = await _pumpPanel(tester, studentId: 'student-1');
    final playPause = find.byKey(const ValueKey('metronome_play_pause_button'));

    await tester.tap(playPause);
    await tester.pump();
    await tester.tap(playPause);
    await tester.pump();

    expect(mock.stopCalled, isTrue);
    expect(mock.capturedStudentId, 'student-1');
    // 짧은 테스트 — 정확한 값까지 검증하지 않고 분 단위 (>= 0) 만 확인.
    expect(mock.capturedMinutes, isNotNull);
    expect(mock.capturedMinutes! >= 0, isTrue);
  });
}
