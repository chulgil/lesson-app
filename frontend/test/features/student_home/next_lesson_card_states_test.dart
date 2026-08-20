import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_home_booking_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/dashboard/next_lesson_card.dart';

/// UXC-11 — 빈 상태는 실제 진입점이어야 하고, 로드 실패가 "레슨 없음" 으로
/// 위장하면 안 된다 (C7: 로딩/빈/에러 분리).
void main() {
  const studentId = 'student_1';

  /// 실 라우터 대신 스파이 라우트를 둔다. 실제 화면은 pending timer 를 남겨
  /// 테스트를 깨뜨리므로, 도착 사실만 기록한다.
  ({GoRouter router, List<String> landed}) buildSpyRouter() {
    final landed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const Scaffold(body: NextLessonCard(studentId: studentId)),
        ),
        GoRoute(
          path: AppRoutes.teacherSearch,
          builder: (context, state) {
            landed.add('teacherSearch');
            return const Scaffold(body: Text('teacher search'));
          },
        ),
      ],
    );
    return (router: router, landed: landed);
  }

  testWidgets(
    'empty state is tappable and lands on the canonical search route',
    (tester) async {
      final spy = buildSpyRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHomeNextLessonProvider(
              studentId,
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(routerConfig: spy.router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.noUpcomingLessons), findsOneWidget);
      // 실제 이동 가능함을 알리는 chevron affordance.
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text(AppStrings.noUpcomingLessons));
      await tester.pumpAndSettle();

      expect(spy.landed, ['teacherSearch']);
    },
  );

  testWidgets('error state is distinct from the empty state', (tester) async {
    final spy = buildSpyRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentHomeNextLessonProvider(
            studentId,
          ).overrideWith((ref) async => throw Exception('network down')),
        ],
        child: MaterialApp.router(routerConfig: spy.router),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.dashboardLessonsLoadError), findsOneWidget);
    // 네트워크 오류가 "예정된 레슨이 없습니다" 로 위장하지 않는다.
    expect(find.text(AppStrings.noUpcomingLessons), findsNothing);
    expect(spy.landed, isEmpty);
  });
}
