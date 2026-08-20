import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_subscription_summary_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_subscription_summary.dart';

void main() {
  testWidgets(
    'UXC-10 empty subscription CTA routes student to teacherSearch, not teacher lessonRequests',
    (tester) async {
      const studentId = 'student_1';
      String? landed;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: StudentSubscriptionSummary(studentId: studentId),
            ),
          ),
          GoRoute(
            path: AppRoutes.teacherSearch,
            builder: (context, state) {
              landed = 'teacherSearch';
              return const Scaffold(body: Text('teacher search'));
            },
          ),
          GoRoute(
            path: AppRoutes.lessonRequests,
            builder: (context, state) {
              landed = 'lessonRequests';
              return const Scaffold(body: Text('teacher lesson requests'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeSubscriptionSummariesProvider(studentId)
                .overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Empty state visible (no subscription).
      expect(
        find.text(AppStrings.subscriptionEmptyRequestLessonCta),
        findsOneWidget,
      );

      await tester.tap(
        find.text(AppStrings.subscriptionEmptyRequestLessonCta),
      );
      await tester.pumpAndSettle();

      expect(landed, 'teacherSearch');
      expect(find.text('teacher search'), findsOneWidget);
    },
  );
}
