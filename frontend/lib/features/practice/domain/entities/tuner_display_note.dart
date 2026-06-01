import 'tuner_settings.dart';
import 'tuner_types.dart';

/// Accidental to draw in staff notation.
enum TunerAccidental { natural, sharp, flat }

/// Display-specific note derived from a detected concert-pitch note.
class TunerDisplayNote {
  const TunerDisplayNote({
    required this.name,
    required this.octave,
    required this.displayName,
    required this.staffNaturalName,
    required this.staffAccidental,
  });

  final NoteName name;
  final int octave;
  final String displayName;
  final String staffNaturalName;
  final TunerAccidental staffAccidental;

  String get fullName => '$displayName$octave';

  static TunerDisplayNote from(TunerNote note, TunerSettings settings) {
    final absoluteSemitone =
        note.name.semitoneIndex +
        note.octave * 12 +
        settings.transposition.semitoneOffset;
    final octave = absoluteSemitone ~/ 12;
    final noteIndex = absoluteSemitone % 12;
    final name = NoteName.values[noteIndex < 0 ? noteIndex + 12 : noteIndex];

    final displayName = switch (settings.enharmonicMode) {
      EnharmonicMode.sharpOnly => name.sharpName,
      EnharmonicMode.flatOnly => name.flatName,
      EnharmonicMode.both => name.enharmonicName,
    };

    final preferFlat = settings.enharmonicMode == EnharmonicMode.flatOnly;
    final staffName = preferFlat ? name.flatName : name.sharpName;
    final staffAccidental =
        !name.isAccidental
            ? TunerAccidental.natural
            : (preferFlat ? TunerAccidental.flat : TunerAccidental.sharp);

    return TunerDisplayNote(
      name: name,
      octave: octave,
      displayName: displayName,
      staffNaturalName: staffName.replaceAll('#', '').replaceAll('b', ''),
      staffAccidental: staffAccidental,
    );
  }
}
