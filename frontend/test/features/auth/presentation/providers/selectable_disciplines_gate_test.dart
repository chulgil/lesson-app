// #1196 — production-exposure gate for the sign-up discipline selection.
//
// Registered disciplines (music/fitness/language) all stay in the registry so
// the multi-Discipline platform (#979-B/#1102) keeps its machinery, but remote/
// production builds must expose ONLY production-ready verticals (music today) so
// new users never land on an unfinished discipline's home. Widget/gate tests run
// with mock defaults, so they keep seeing every discipline unchanged.
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/features/auth/presentation/providers/active_discipline_provider.dart';

void main() {
  group('#1196 discipline production-exposure gate', () {
    test('registry productionReady subset = [music] only', () {
      expect(DisciplineRegistry.productionReady.map((d) => d.id).toList(), [
        'music',
      ]);
    });

    test('remote/prod build (useMock:false) exposes only production-ready', () {
      expect(selectableDisciplines(useMock: false).map((d) => d.id).toList(), [
        'music',
      ]);
    });

    test(
      'mock/dev build (useMock:true) exposes every registered discipline',
      () {
        expect(
          selectableDisciplines(useMock: true).map((d) => d.id).toList(),
          DisciplineRegistry.all.map((d) => d.id).toList(),
        );
      },
    );
  });
}
