import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/value_objects/audio_mix_mode.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/audio_mix_guide_dialog.dart';

void main() {
  group('AudioMixGuideDialog — §5.4', () {
    testWidgets('renders with headphone-missing message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AudioMixGuideDialog(headphoneConnected: false)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('녹음 모드 선택'), findsOneWidget);
      expect(
        find.text('헤드폰을 권장합니다. 메트로놈/영상 소리가 녹음에 섞일 수 있어요.'),
        findsOneWidget,
      );
      expect(find.text('헤드폰 연결 안내'), findsOneWidget);
    });

    testWidgets(
      'with headphones connected does not show "connect headphones" option',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AudioMixGuideDialog(headphoneConnected: true)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('헤드폰 연결 안내'), findsNothing);
      },
    );
  });

  group('mapGuideResultToMode — §5.4', () {
    test('muteVideo → videoMuted', () {
      expect(
        mapGuideResultToMode(
          AudioMixGuideResult.muteVideo,
          metronomeActive: false,
          headphoneConnected: false,
        ),
        AudioMixMode.videoMuted,
      );
    });

    test('continueAnyway with headphone → headphoneOnly', () {
      expect(
        mapGuideResultToMode(
          AudioMixGuideResult.continueAnyway,
          metronomeActive: false,
          headphoneConnected: true,
        ),
        AudioMixMode.headphoneOnly,
      );
    });

    test('continueAnyway with metronome+headphone → metronomeMixed', () {
      expect(
        mapGuideResultToMode(
          AudioMixGuideResult.continueAnyway,
          metronomeActive: true,
          headphoneConnected: true,
        ),
        AudioMixMode.metronomeMixed,
      );
    });

    test('continueAnyway with no headphone → mixed', () {
      expect(
        mapGuideResultToMode(
          AudioMixGuideResult.continueAnyway,
          metronomeActive: false,
          headphoneConnected: false,
        ),
        AudioMixMode.mixed,
      );
    });

    test('dismissed → recordOnly', () {
      expect(
        mapGuideResultToMode(
          AudioMixGuideResult.dismissed,
          metronomeActive: false,
          headphoneConnected: false,
        ),
        AudioMixMode.recordOnly,
      );
    });
  });
}
