import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/presentation/widgets/bound_volume_spine.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: child))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('완성본 책등 — VOL. + 로마숫자(I) 렌더, 크래시 없음', (tester) async {
    await pump(tester, const BoundVolumeSpine(volumeNo: 1, title: '나비야'));
    expect(tester.takeException(), isNull);
    expect(find.text('VOL.'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('나비야'), findsOneWidget);
  });

  testWidgets('연습중 책등 — 점선·연습중 라벨, 로마숫자 없음', (tester) async {
    await pump(tester, const BoundVolumeSpine(title: '작은별'));
    expect(tester.takeException(), isNull);
    expect(find.text('연습중'), findsOneWidget);
    expect(find.text('VOL.'), findsNothing);
    expect(find.text('작은별'), findsOneWidget);
  });

  testWidgets('volumeNo 4 → 로마 IV (0-based romanOf)', (tester) async {
    await pump(tester, const BoundVolumeSpine(volumeNo: 4, title: 'x'));
    expect(tester.takeException(), isNull);
    expect(find.text('IV'), findsOneWidget);
  });
}
