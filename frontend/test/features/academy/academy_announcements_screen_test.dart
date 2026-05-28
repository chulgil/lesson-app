import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/notifications/presentation/screens/academy_announcements_screen.dart';

void main() {
  group('AcademyAnnouncementsScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AcademyAnnouncementsScreen(academyId: 'acad_001')),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.announcementsTitle), findsOneWidget);
    });

    testWidgets('displays announcements list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AcademyAnnouncementsScreen(academyId: 'acad_001')),
      );

      await tester.pumpAndSettle();
      expect(find.text('여름 방학 수강 안내'), findsOneWidget);
    });
  });
}
