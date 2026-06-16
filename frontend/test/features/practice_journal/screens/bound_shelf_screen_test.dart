import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/providers/repertoire_archive_provider.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/bound_volume.dart';
import 'package:lessonaza/features/practice_journal/presentation/providers/practice_journal_provider.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/bound_shelf_screen.dart';

void main() {
  PracticeRepertoire activeRep(String id, String name) => PracticeRepertoire(
    id: id,
    studentId: 'c1',
    name: name,
    startDate: DateTime(2026, 6, 1),
    createdAt: DateTime(2026, 6, 1),
  );

  BoundVolume vol(int n, String name) => BoundVolume(
    childProfileId: 'c1',
    pieceId: 'p$n',
    pieceName: name,
    volumeNo: n,
    boundDate: DateTime(2026, 3, n),
  );

  Future<void> pumpShelf(
    WidgetTester tester, {
    required List<BoundVolume> bound,
    required List<PracticeRepertoire> active,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boundVolumesProvider('c1').overrideWith((ref) async => bound),
          activeRepertoiresProvider('c1').overrideWith((ref) async => active),
        ],
        child: const MaterialApp(home: BoundShelfScreen(childProfileId: 'c1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('완성본 + 연습중 구분 렌더, 크래시 없음', (tester) async {
    await pumpShelf(
      tester,
      bound: [vol(1, '나비야')],
      active: [activeRep('r1', '연습중곡')],
    );
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.boundShelfCompletedSection), findsOneWidget);
    expect(find.text('VOL.'), findsOneWidget);
    expect(find.text('나비야'), findsOneWidget);
    expect(find.text('연습중곡'), findsOneWidget);
  });

  testWidgets('완성본·연습중 모두 없으면 빈 상태', (tester) async {
    await pumpShelf(tester, bound: const [], active: const []);
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.boundShelfEmptyTitle), findsOneWidget);
  });
}
