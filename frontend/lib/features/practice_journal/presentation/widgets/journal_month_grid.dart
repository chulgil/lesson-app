import 'package:flutter/material.dart';

import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_glyph.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_ledger.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

/// 7-열 월간 연습 도장 그리드 (스펙 §5.1 / §10).
///
/// - 7컬럼 고정 (월~일).
/// - full → ● (dotFilled, AppColors.ink)
/// - short → ○ (dotOutline, AppColors.ink)
/// - 빈 날 → · (middleDot, AppColors.inkQuaternary) — 비처벌 디자인
/// - [BorderRadius.zero], [Icons.*] 금지, [Color(0x...)] 리터럴 금지.
class JournalMonthGrid extends StatelessWidget {
  final PracticeLedger ledger;

  const JournalMonthGrid({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.utc(ledger.year, ledger.month, 1);
    // 월요일=0, 일요일=6 (weekday: 1=Mon … 7=Sun)
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime.utc(ledger.year, ledger.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;

    // 날짜 → PracticeMark 빠른 조회 맵
    final markMap = <int, MarkIntensity>{};
    for (final mark in ledger.marks) {
      if (mark.date.year == ledger.year && mark.date.month == ledger.month) {
        markMap[mark.date.day] = mark.intensity;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space2),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.space1,
        crossAxisSpacing: AppSpacing.space1,
        children: List.generate(totalCells, (index) {
          if (index < startOffset) {
            // 이전 달 빈 칸
            return const SizedBox.shrink();
          }
          final day = index - startOffset + 1;
          final intensity = markMap[day];
          return Center(child: _DayCell(day: day, intensity: intensity));
        }),
      ),
    );
  }
}

/// 하루 한 칸. 연습 강도에 따라 글리프 선택.
class _DayCell extends StatelessWidget {
  final int day;
  final MarkIntensity? intensity;

  const _DayCell({required this.day, required this.intensity});

  @override
  Widget build(BuildContext context) {
    final String glyph;
    final Color color;

    switch (intensity) {
      case MarkIntensity.full:
        glyph = NotebookGlyph.dotFilled; // ●
        color = AppColors.ink;
      case MarkIntensity.short:
        glyph = NotebookGlyph.dotOutline; // ○
        color = AppColors.ink;
      case null:
        glyph = NotebookGlyph.middleDot; // ·
        color = AppColors.inkQuaternary;
    }

    return NotebookGlyph(
      glyph,
      size: AppSpacing.iconXS,
      color: color,
      semanticLabel: intensity != null ? '연습 완료 $day일' : null,
    );
  }
}
