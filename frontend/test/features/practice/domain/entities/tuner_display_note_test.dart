import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_display_note.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_settings.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_types.dart';

void main() {
  group('TunerDisplayNote', () {
    test('keeps concert-pitch instruments unchanged', () {
      const note = TunerNote(
        name: NoteName.A,
        octave: 4,
        frequency: 440,
        centDeviation: 0,
      );

      final display = TunerDisplayNote.from(note, const TunerSettings());

      expect(display.name, NoteName.A);
      expect(display.octave, 4);
      expect(display.fullName, 'A4');
      expect(display.staffNaturalName, 'A');
      expect(display.staffAccidental, TunerAccidental.natural);
    });

    test('transposes concert pitch to written pitch for wind instruments', () {
      const concertC4 = TunerNote(
        name: NoteName.C,
        octave: 4,
        frequency: 261.63,
        centDeviation: 0,
      );

      expect(
        TunerDisplayNote.from(
          concertC4,
          const TunerSettings(transposition: Transposition.bb),
        ).fullName,
        'D4',
      );
      expect(
        TunerDisplayNote.from(
          concertC4,
          const TunerSettings(transposition: Transposition.eb),
        ).fullName,
        'A4',
      );
      expect(
        TunerDisplayNote.from(
          concertC4,
          const TunerSettings(transposition: Transposition.f),
        ).fullName,
        'G4',
      );
      expect(
        TunerDisplayNote.from(
          concertC4,
          const TunerSettings(transposition: Transposition.a),
        ).fullName,
        'D#4',
      );
    });

    test('updates octave when transposition crosses an octave boundary', () {
      const concertB4 = TunerNote(
        name: NoteName.B,
        octave: 4,
        frequency: 493.88,
        centDeviation: 0,
      );

      final display = TunerDisplayNote.from(
        concertB4,
        const TunerSettings(transposition: Transposition.bb),
      );

      expect(display.name, NoteName.Cs);
      expect(display.octave, 5);
      expect(display.fullName, 'C#5');
    });

    test('uses flat spelling and staff position in flat mode', () {
      const concertC4 = TunerNote(
        name: NoteName.C,
        octave: 4,
        frequency: 261.63,
        centDeviation: 0,
      );

      final display = TunerDisplayNote.from(
        concertC4,
        const TunerSettings(
          transposition: Transposition.bb,
          enharmonicMode: EnharmonicMode.flatOnly,
        ),
      );

      expect(display.fullName, 'D4');
      expect(display.staffNaturalName, 'D');
      expect(display.staffAccidental, TunerAccidental.natural);

      final flatDisplay = TunerDisplayNote.from(
        const TunerNote(
          name: NoteName.Cs,
          octave: 4,
          frequency: 277.18,
          centDeviation: 0,
        ),
        const TunerSettings(enharmonicMode: EnharmonicMode.flatOnly),
      );

      expect(flatDisplay.fullName, 'Db4');
      expect(flatDisplay.staffNaturalName, 'D');
      expect(flatDisplay.staffAccidental, TunerAccidental.flat);
    });
  });
}
