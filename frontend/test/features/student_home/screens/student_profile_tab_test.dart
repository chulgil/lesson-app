import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_masthead.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_profile_provider.dart';
import 'package:lessonaza/features/student_home/presentation/screens/student_profile_tab.dart';

void main() {
  group('StudentProfileTab — #89 masthead/menu 정비 smoke', () {
    const fakeProfile = StudentHomeProfileState(
      studentId: 'student-1',
      name: '홍길동',
      initial: '홍',
      email: 'hong@example.com',
      instrument: '바이올린',
      lessonCountLabel: '12회',
      practiceTimeLabel: '8시간',
      lessonPeriodLabel: '3개월',
      repertoireCount: 2,
      teacherSubtitle: '김선생님',
    );

    Future<void> pumpTab(WidgetTester tester) async {
      // 440x900: pre-existing masthead 폭 오버플로 회피 (별도 이슈).
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeProfileProvider.overrideWithValue(fakeProfile),
          ],
          child: const MaterialApp(home: Scaffold(body: StudentProfileTab())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders without exceptions after masthead gear removal', (
      tester,
    ) async {
      await pumpTab(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'masthead has no settings gear; single settings entry row exists',
      (tester) async {
        await pumpTab(tester);
        // #89: masthead gear (Icons.settings_outlined) was a duplicate of the
        // explicit "알림 설정" menu item and has been removed — still true.
        expect(
          find.descendant(
            of: find.byType(NotebookMasthead),
            matching: find.byIcon(Icons.settings_outlined),
          ),
          findsNothing,
        );
        // Settings sub-hub split: the 6 flattened settings rows collapsed
        // into a single "설정" entry row (student_settings_hub_screen.dart).
        expect(find.text(AppStrings.studentHomeSettingsTitle), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('StudentProfileTab — settings entry navigation', () {
    const fakeProfile = StudentHomeProfileState(
      studentId: 'student-1',
      name: '홍길동',
      initial: '홍',
      email: 'hong@example.com',
      instrument: '바이올린',
      lessonCountLabel: '12회',
      practiceTimeLabel: '8시간',
      lessonPeriodLabel: '3개월',
      repertoireCount: 2,
      teacherSubtitle: '김선생님',
    );

    testWidgets('tapping the 설정 row navigates to the settings hub route', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? landed;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder:
                (context, state) => const Scaffold(body: StudentProfileTab()),
          ),
          GoRoute(
            path: AppRoutes.studentSettingsHub,
            builder: (context, state) {
              landed = 'studentSettingsHub';
              return const Scaffold(body: Text('settings hub'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeProfileProvider.overrideWithValue(fakeProfile),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 설정 행은 스크롤 하단에 위치 — 먼저 화면 안으로 스크롤.
      final entry = find.text(AppStrings.studentHomeSettingsTitle);
      await tester.scrollUntilVisible(entry, 200);
      await tester.pumpAndSettle();

      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(landed, 'studentSettingsHub');
      expect(find.text('settings hub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
