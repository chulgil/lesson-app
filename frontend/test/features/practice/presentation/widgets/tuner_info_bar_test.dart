import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_settings.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_types.dart';
import 'package:lessonaza/features/practice/presentation/providers/tuner_provider.dart';
import 'package:lessonaza/features/practice/presentation/widgets/tuner/circular_tuner_indicator.dart';

void main() {
  testWidgets('TunerInfoBar uses the transposed display note text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tunerProvider.overrideWith(_TransposedTuner.new)],
        child: const MaterialApp(home: Scaffold(body: TunerInfoBar())),
      ),
    );

    expect(find.text('D4 · 261.6Hz · +0.0¢'), findsOneWidget);
  });
}

class _TransposedTuner extends Tuner {
  @override
  TunerProviderState build() {
    return const TunerProviderState(
      settings: TunerSettings(transposition: Transposition.bb),
      currentNote: TunerNote(
        name: NoteName.C,
        octave: 4,
        frequency: 261.63,
        centDeviation: 0,
      ),
      status: TuningStatus.tuned,
      isInitialized: true,
    );
  }
}
