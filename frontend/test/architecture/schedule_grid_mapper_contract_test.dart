// docs/specs/schedule/schedule_change_unification_spec.md §3.2/§4 (M-4) —
// "2 컴포넌트, 1 인터랙션 문법" contract for WeeklyCalendarPicker /
// AlternativeTimeGrid: (1) the dayOfWeek indexing shift between the grid's
// 1-indexed TimeSlot and the request-domain's 0-indexed PreferredTimeSlot /
// TimeSlotOption must live in exactly one mapper file, and (2) both grids
// keep the shared maxSlots=3 default.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayOfWeek indexing arithmetic for PreferredTimeSlot/TimeSlotOption '
      'lives only in the M-4 mapper', () {
    final violations = <String>[];

    // Matches the exact anti-pattern this mapper replaces: constructing a
    // TimeSlotOption/PreferredTimeSlot's `dayOfWeek:` field from another
    // slot's `.dayOfWeek` with inline +1/-1 arithmetic (request_detail_
    // screen.dart:529 pre-M-4, and the un-adjusted duplicate in
    // subscription_detail_screen.dart fixed by this same change).
    final inlineConversionPattern = RegExp(
      r'dayOfWeek:\s*[\w.!]*\.dayOfWeek\s*[+-]\s*1\b',
    );

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith(
        'lib/features/schedule/domain/mappers/time_slot_mapper.dart',
      )) {
        continue;
      }

      final content = file.readAsStringSync();
      if (inlineConversionPattern.hasMatch(content)) {
        violations.add(normalizedPath);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'dayOfWeek +1/-1 conversion between TimeSlot and '
          'PreferredTimeSlot/TimeSlotOption must go through '
          'lib/features/schedule/domain/mappers/time_slot_mapper.dart '
          '(toTimeSlotOption()/toPreferredTimeSlot()/toTimeSlot()), not '
          'inline screen code. Violations: $violations',
    );
  });

  test('WeeklyCalendarPicker and AlternativeTimeGrid share maxSlots=3', () {
    final weeklyCalendarPicker =
        File(
          'lib/features/schedule/presentation/widgets/weekly_calendar_picker.dart',
        ).readAsStringSync();
    final alternativeTimeGrid =
        File(
          'lib/features/schedule/presentation/widgets/alternative_time_grid.dart',
        ).readAsStringSync();

    expect(
      weeklyCalendarPicker,
      contains('SlotSelectionLogic(maxSlots: 3)'),
      reason:
          'WeeklyCalendarPicker must keep the §3.2 shared maxSlots=3 '
          'contract.',
    );
    expect(
      alternativeTimeGrid,
      contains('this.maxSlots = 3'),
      reason:
          'AlternativeTimeGrid must keep the §3.2 shared maxSlots=3 '
          'default.',
    );
  });
}
