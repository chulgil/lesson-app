import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/spotlight_type.dart';

void main() {
  group('SpotlightType', () {
    test('has 3 spec-defined values', () {
      expect(SpotlightType.values.length, 3);
      expect(
        SpotlightType.values,
        containsAll([
          SpotlightType.teacherRec,
          SpotlightType.seasonEvent,
          SpotlightType.routineSuggestion,
        ]),
      );
    });

    test('name is stable JSON key', () {
      expect(SpotlightType.teacherRec.name, 'teacherRec');
      expect(SpotlightType.seasonEvent.name, 'seasonEvent');
      expect(SpotlightType.routineSuggestion.name, 'routineSuggestion');
    });

    test('fromName round-trips for all spec names', () {
      for (final t in SpotlightType.values) {
        expect(SpotlightType.fromName(t.name), t);
      }
    });

    test('fromName throws on unknown name (no silent fallback)', () {
      expect(
        () => SpotlightType.fromName('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
