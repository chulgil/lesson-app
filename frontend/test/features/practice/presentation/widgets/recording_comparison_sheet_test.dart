// #495 — recording_comparison_sheet smoke test (practice §4.5).
//
// Mocks audioplayers method channels so AudioPlayer() construction does not
// throw MissingPluginException during unit-test pumpWidget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/widgets/recording_comparison_sheet.dart';

PracticeRecording _rec({
  required String id,
  required DateTime createdAt,
  int durationSeconds = 60,
  int? bpm,
}) {
  return PracticeRecording(
    id: id,
    sectionId: 'sec_1',
    filePath: '/tmp/$id.m4a',
    durationSeconds: durationSeconds,
    bpm: bpm,
    createdAt: createdAt,
  );
}

void _mockAudioplayers() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // Per-player channel.
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );
  // Global channel.
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _mockAudioplayers();
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
  });

  Widget wrap(List<PracticeRecording> recordings) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) {
            return Center(
              child: ElevatedButton(
                onPressed: () => showRecordingComparisonSheet(ctx, recordings),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
  }

  final recordings = [
    _rec(id: 'a', createdAt: DateTime(2026, 5, 1), bpm: 96),
    _rec(id: 'b', createdAt: DateTime(2026, 5, 5), bpm: 110),
    _rec(id: 'c', createdAt: DateTime(2026, 5, 8), bpm: 120),
  ];

  testWidgets('shows compare title and Step 1 select label on open', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(recordings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.practiceRecordingCompareTitle), findsOneWidget);
    expect(find.textContaining('Step 1/2'), findsOneWidget);
  });

  testWidgets('Step 1 tap advances to Step 2 with only later recordings', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(recordings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap the earliest recording row to pick A.
    final dateA = '2026.05.01';
    expect(find.textContaining(dateA), findsOneWidget);
    await tester.tap(find.textContaining(dateA));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Step 2 label visible.
    expect(find.textContaining('Step 2/2'), findsOneWidget);
    // Earliest recording (A) should be filtered out from B-candidate list.
    expect(find.textContaining(dateA), findsNothing);
    // Later recordings still present.
    expect(find.textContaining('2026.05.05'), findsOneWidget);
    expect(find.textContaining('2026.05.08'), findsOneWidget);
  });

  testWidgets('narrow viewport: no layout overflow on open', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(recordings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.practiceRecordingCompareTitle), findsOneWidget);
  });
}
