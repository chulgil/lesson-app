import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';

void main() {
  group('TimeSignature enum', () {
    test('has 4 simple time signatures', () {
      final simple = TimeSignature.values.where((ts) => ts.isSimple).toList();
      expect(simple.length, 4);
      expect(simple.map((ts) => ts.label).toList(),
          ['1/4', '2/4', '3/4', '4/4']);
    });

    test('has 4 compound time signatures', () {
      final compound =
          TimeSignature.values.where((ts) => ts.isCompound).toList();
      expect(compound.length, 4);
      expect(compound.map((ts) => ts.label).toList(),
          ['3/8', '6/8', '9/8', '12/8']);
    });

    test('total 8 time signatures', () {
      expect(TimeSignature.values.length, 8);
    });
  });

  group('Simple time signatures — beatsPerMeasure', () {
    test('1/4: 1 beat per measure', () {
      expect(TimeSignature.oneFour.beatsPerMeasure, 1);
      expect(TimeSignature.oneFour.beatUnit, 4);
      expect(TimeSignature.oneFour.isSimple, true);
      expect(TimeSignature.oneFour.mainBeats, 1);
    });

    test('2/4: 2 beats per measure', () {
      expect(TimeSignature.twoFour.beatsPerMeasure, 2);
      expect(TimeSignature.twoFour.beatUnit, 4);
      expect(TimeSignature.twoFour.mainBeats, 2);
    });

    test('3/4: 3 beats per measure', () {
      expect(TimeSignature.threeFour.beatsPerMeasure, 3);
      expect(TimeSignature.threeFour.beatUnit, 4);
      expect(TimeSignature.threeFour.mainBeats, 3);
    });

    test('4/4: 4 beats per measure', () {
      expect(TimeSignature.fourFour.beatsPerMeasure, 4);
      expect(TimeSignature.fourFour.beatUnit, 4);
      expect(TimeSignature.fourFour.mainBeats, 4);
    });
  });

  group('Compound time signatures — mainBeats', () {
    test('3/8: 3 beats, compound, mainBeats=1', () {
      expect(TimeSignature.threeEight.beatsPerMeasure, 3);
      expect(TimeSignature.threeEight.beatUnit, 8);
      expect(TimeSignature.threeEight.isCompound, true);
      expect(TimeSignature.threeEight.mainBeats, 1);
    });

    test('6/8: 6 beats, compound, mainBeats=2', () {
      expect(TimeSignature.sixEight.beatsPerMeasure, 6);
      expect(TimeSignature.sixEight.beatUnit, 8);
      expect(TimeSignature.sixEight.isCompound, true);
      expect(TimeSignature.sixEight.mainBeats, 2);
    });

    test('9/8: 9 beats, compound, mainBeats=3', () {
      expect(TimeSignature.nineEight.beatsPerMeasure, 9);
      expect(TimeSignature.nineEight.beatUnit, 8);
      expect(TimeSignature.nineEight.isCompound, true);
      expect(TimeSignature.nineEight.mainBeats, 3);
    });

    test('12/8: 12 beats, compound, mainBeats=4', () {
      expect(TimeSignature.twelveEight.beatsPerMeasure, 12);
      expect(TimeSignature.twelveEight.beatUnit, 8);
      expect(TimeSignature.twelveEight.isCompound, true);
      expect(TimeSignature.twelveEight.mainBeats, 4);
    });
  });

  group('Labels are correctly formatted', () {
    test('simple labels: numerator/denominator', () {
      expect(TimeSignature.oneFour.label, '1/4');
      expect(TimeSignature.twoFour.label, '2/4');
      expect(TimeSignature.threeFour.label, '3/4');
      expect(TimeSignature.fourFour.label, '4/4');
    });

    test('compound labels: numerator/denominator', () {
      expect(TimeSignature.threeEight.label, '3/8');
      expect(TimeSignature.sixEight.label, '6/8');
      expect(TimeSignature.nineEight.label, '9/8');
      expect(TimeSignature.twelveEight.label, '12/8');
    });

    test('no 4/1 exists (was a bug)', () {
      final labels = TimeSignature.values.map((ts) => ts.label).toList();
      expect(labels.contains('4/1'), false);
    });
  });
}
