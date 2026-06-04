import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_report.dart';
import 'package:lessonaza/features/practice/presentation/widgets/report/repertoire_ratio_bar.dart';

void main() {
  Widget host(Widget child, {double width = 360}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );
  }

  testWidgets('shows empty message when no ratios', (tester) async {
    await tester.pumpWidget(host(const RepertoireRatioBar(ratios: [])));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.practiceReportRepertoireRatioTitle),
      findsOneWidget,
    );
    expect(find.text(AppStrings.practiceReportEmptyRepertoire), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders rows with name and percent', (tester) async {
    const ratios = [
      RepertoireRatio(
        repertoireId: 'a',
        repertoireName: 'Bach Partita',
        practiceSeconds: 1800,
        ratio: 0.6,
      ),
      RepertoireRatio(
        repertoireId: 'b',
        repertoireName: 'Mozart Sonata',
        practiceSeconds: 1200,
        ratio: 0.4,
      ),
    ];
    await tester.pumpWidget(host(const RepertoireRatioBar(ratios: ratios)));
    await tester.pumpAndSettle();

    expect(find.text('Bach Partita'), findsOneWidget);
    expect(find.text('Mozart Sonata'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without layout exception at narrow width', (
    tester,
  ) async {
    const ratios = [
      RepertoireRatio(
        repertoireId: 'a',
        repertoireName: 'Very very long repertoire name that overflows easily',
        practiceSeconds: 1800,
        ratio: 0.6,
      ),
    ];
    await tester.pumpWidget(
      host(const RepertoireRatioBar(ratios: ratios), width: 180),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
