import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_report.dart';
import 'package:lessonaza/features/practice/domain/services/practice_report_calculator.dart';

void main() {
  const calculator = PracticeReportCalculator();

  group('PracticeReportCalculator.calculateWeekly', () {
    test('empty inputs → zero totals, 7 daily entries', () {
      final report = calculator.calculateWeekly(
        weekStart: DateTime(2026, 6, 1),
        inputs: const [],
      );

      expect(report.totalPracticeSeconds, 0);
      expect(report.practiceDayCount, 0);
      expect(report.dailyEntries.length, 7);
      expect(report.repertoireRatios, isEmpty);
      expect(report.isEmpty, isTrue);
    });

    test('sums seconds per day and ignores rows outside the week', () {
      final report = calculator.calculateWeekly(
        weekStart: DateTime(2026, 6, 1), // Monday
        inputs: [
          DailyPracticeInput(
            date: DateTime(2026, 6, 1),
            repertoireId: 'rep_1',
            repertoireName: 'Bach',
            practiceSeconds: 600,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 6, 1),
            repertoireId: 'rep_2',
            repertoireName: 'Mozart',
            practiceSeconds: 300,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 6, 3),
            repertoireId: 'rep_1',
            repertoireName: 'Bach',
            practiceSeconds: 1200,
          ),
          // outside the week — must be ignored
          DailyPracticeInput(
            date: DateTime(2026, 5, 31),
            repertoireId: 'rep_1',
            repertoireName: 'Bach',
            practiceSeconds: 999,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 6, 8),
            repertoireId: 'rep_1',
            repertoireName: 'Bach',
            practiceSeconds: 999,
          ),
        ],
      );

      expect(report.totalPracticeSeconds, 600 + 300 + 1200);
      expect(report.practiceDayCount, 2);
      expect(report.dailyEntries[0].practiceSeconds, 900); // Mon
      expect(report.dailyEntries[2].practiceSeconds, 1200); // Wed
      expect(report.dailyEntries[1].practiceSeconds, 0); // Tue
    });

    test('repertoire ratios sum to ~1.0 and are sorted desc', () {
      final report = calculator.calculateWeekly(
        weekStart: DateTime(2026, 6, 1),
        inputs: [
          DailyPracticeInput(
            date: DateTime(2026, 6, 1),
            repertoireId: 'a',
            repertoireName: 'A',
            practiceSeconds: 100,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 6, 2),
            repertoireId: 'b',
            repertoireName: 'B',
            practiceSeconds: 300,
          ),
        ],
      );

      expect(report.repertoireRatios.length, 2);
      expect(report.repertoireRatios.first.repertoireId, 'b');
      expect(report.repertoireRatios.first.ratio, closeTo(0.75, 0.001));
      expect(report.repertoireRatios.last.ratio, closeTo(0.25, 0.001));
    });
  });

  group('PracticeReportCalculator.calculateMonthly', () {
    test('empty inputs → zero totals, full month of daily entries', () {
      final report = calculator.calculateMonthly(
        year: 2026,
        month: 6,
        inputs: const [],
      );

      expect(report.totalPracticeSeconds, 0);
      expect(report.practiceDayCount, 0);
      expect(report.dailyEntries.length, 30); // June has 30 days
      expect(report.isEmpty, isTrue);
    });

    test('sums all in-range rows, ignores other months', () {
      final report = calculator.calculateMonthly(
        year: 2026,
        month: 6,
        inputs: [
          DailyPracticeInput(
            date: DateTime(2026, 6, 5),
            repertoireId: 'a',
            repertoireName: 'A',
            practiceSeconds: 1200,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 6, 20),
            repertoireId: 'a',
            repertoireName: 'A',
            practiceSeconds: 1800,
          ),
          // wrong month
          DailyPracticeInput(
            date: DateTime(2026, 5, 30),
            repertoireId: 'a',
            repertoireName: 'A',
            practiceSeconds: 99999,
          ),
          DailyPracticeInput(
            date: DateTime(2026, 7, 1),
            repertoireId: 'a',
            repertoireName: 'A',
            practiceSeconds: 99999,
          ),
        ],
      );

      expect(report.totalPracticeSeconds, 3000);
      expect(report.totalMinutes, 50);
      expect(report.practiceDayCount, 2);
      expect(report.averageDailyMinutes, 25);
    });
  });

  group('DailyReportEntry / RepertoireRatio derived', () {
    test('practiceMinutes truncates seconds', () {
      final entry = DailyReportEntry(
        date: DateTime(2026, 6, 1),
        practiceSeconds: 119,
      );
      expect(entry.practiceMinutes, 1);
      expect(entry.hasPracticed, isTrue);
    });

    test('ratioPercent rounds correctly', () {
      const ratio = RepertoireRatio(
        repertoireId: 'a',
        repertoireName: 'A',
        practiceSeconds: 600,
        ratio: 0.336,
      );
      expect(ratio.ratioPercent, 34);
      expect(ratio.practiceMinutes, 10);
    });
  });
}
