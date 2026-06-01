import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/recording_waveform.dart';

void main() {
  testWidgets('unzoomed waveform drag scrubs to the dragged position', (
    tester,
  ) async {
    final seeks = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ZoomableWaveformProgressBar(
                progress: 0,
                duration: const Duration(seconds: 60),
                onSeek: seeks.add,
              ),
            ),
          ),
        ),
      ),
    );

    final bar = find.byType(ZoomableWaveformProgressBar);
    final start = tester.getCenter(bar) - const Offset(90, 0);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(180, 0));
    await tester.pump();

    expect(
      seeks,
      isNotEmpty,
      reason: 'Dragging should scrub while the finger is still down.',
    );

    await gesture.up();

    expect(seeks.last, closeTo(0.8, 0.08));
  });
}
