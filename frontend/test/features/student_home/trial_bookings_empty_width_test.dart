import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/trial_bookings_section.dart';

void main() {
  testWidgets(
    '#632/#636 empty trial card renders full-width with paper bg (not a left square)',
    (tester) async {
      const studentId = 'student_1';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeTrialBookingsProvider(
              studentId,
            ).overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [TrialBookingsSection(studentId: studentId)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final width = tester.getSize(find.byType(TrialBookingsSection)).width;
      expect(width, greaterThan(700)); // full-width (~800), not intrinsic narrow

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(TrialBookingsSection),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration?)?.color, AppColors.paper);
    },
  );
}
