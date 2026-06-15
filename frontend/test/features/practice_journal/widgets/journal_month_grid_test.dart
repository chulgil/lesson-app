import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';
import 'package:lessonaza/features/practice_journal/presentation/widgets/journal_month_grid.dart';

void main() {
  testWidgets('JournalMonthGrid 렌더(좁은 제약) 예외 없음', (tester) async {
    final ledger = PracticeLedger.empty(
          childProfileId: 'c1',
          year: 2026,
          month: 6,
        )
        .upsertMark(DateTime.utc(2026, 6, 15), MarkIntensity.full)
        .upsertMark(DateTime.utc(2026, 6, 16), MarkIntensity.short);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, child: JournalMonthGrid(ledger: ledger)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
