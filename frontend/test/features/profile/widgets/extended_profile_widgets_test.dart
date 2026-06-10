// Widget smoke test (HARD-GATE) for EducationCard / CareerCard / CertificateCard.
//
// Asserts the swipe consistency followup audit #668 D5 — the legacy
// PopupMenuButton has been replaced by SwipeActionTile + tap-to-edit, and
// each card renders without runtime crashes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/presentation/widgets/extended_profile_widgets.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );

  group('EducationCard', () {
    testWidgets('renders without crash and exposes no PopupMenu', (
      tester,
    ) async {
      const education = Education(
        school: '서울대학교',
        major: '음악학',
        degree: 'Bachelor',
        graduationYear: 2020,
      );

      await tester.pumpWidget(
        wrap(const EducationCard(education: education, index: 0)),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('서울대학교'), findsOneWidget);
    });
  });

  group('CareerCard', () {
    testWidgets('renders without crash and exposes no PopupMenu', (
      tester,
    ) async {
      const career = Career(
        organization: '한국예술종합학교',
        position: '강사',
        startYear: 2020,
      );

      await tester.pumpWidget(wrap(const CareerCard(career: career, index: 0)));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('한국예술종합학교'), findsOneWidget);
    });
  });

  group('CertificateCard', () {
    testWidgets('renders without crash and exposes no PopupMenu', (
      tester,
    ) async {
      final certificate = Certificate(
        id: 'cert-1',
        type: CertificateType.musicTeacher,
        name: '음악 교원 자격증',
        issuingBody: '교육부',
        issueDate: DateTime(2023, 5, 1),
        imageUrl: 'https://example.com/cert.png',
        status: CertificateStatus.approved,
        submittedAt: DateTime(2023, 5, 1),
      );

      await tester.pumpWidget(wrap(CertificateCard(certificate: certificate)));

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.text('음악 교원 자격증'), findsOneWidget);
    });
  });
}
