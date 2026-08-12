// 일정변경 응답 목적지 단일화 — 홈 ScheduleChangeRequestSection 라우팅 검증.
//
// 조사 결론(2026-08 갱신): 홈 섹션이 읽는 RequestEvent(mock 세션 스토어)는
// requestId 가 UnifiedLessonRequest.id 를 가리키지 않는다 (subscriptionId 를
// 그대로 재사용). 하지만 ScheduleConfirmationCard 역조회
// (lessonRequestIdBySubscriptionProvider, Option A)로 원 요청 스레드를 찾을 수
// 있는 경우가 생겼다 — 탭 시점에 이 provider 를 조회해 링크가 있으면
// RequestDetailScreen 으로, 없으면(갱신/교사 직접 제안) 기존처럼
// subscriptionDetail + highlightScheduleResponse 로 이동한다. — 실제
// context.go() 는 Timer-pending 크래시를 유발하므로 spy GoRouter 로 목적지
// push 를 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/home/presentation/widgets/schedule_change_request_section.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/schedule_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _teacherId = 'teacher_1';

RequestEvent _pendingEvent({
  required String id,
  required String actorId,
  String? subscriptionId,
  int? sessionNumber,
}) {
  return RequestEvent(
    id: id,
    requestId: subscriptionId ?? 'ulr_unrelated',
    actorType: ProposerRole.student,
    actorId: actorId,
    eventType: RequestEventType.scheduleChanged,
    message: '개인 일정이 변경되어 시간 변경을 요청합니다',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    scheduleChangeType: ScheduleChangeType.singleLesson,
    subscriptionId: subscriptionId,
    sessionNumber: sessionNumber,
  );
}

/// Builds a spy GoRouter capturing pushes to [AppRoutes.subscriptionDetail]
/// and [AppRoutes.requestDetail].
GoRouter _spyRouter({
  required List<Map<String, Object?>> visited,
  required Widget home,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: AppRoutes.subscriptionDetail,
        builder: (context, state) {
          visited.add({
            'route': 'subscriptionDetail',
            'id': state.pathParameters['id'],
            'session': state.uri.queryParameters['session'],
            'extra': state.extra,
          });
          return const Scaffold(body: Text('subscription-detail'));
        },
      ),
      GoRoute(
        path: AppRoutes.requestDetail,
        builder: (context, state) {
          visited.add({
            'route': 'requestDetail',
            'id': state.pathParameters['id'],
            'extra': state.extra,
          });
          return const Scaffold(body: Text('request-detail'));
        },
      ),
    ],
  );
}

void main() {
  group('ScheduleChangeRequestSection 라우팅', () {
    testWidgets('연결된 원 요청이 없으면(갱신/교사 직접 제안) subscriptionDetail 로 이동하고 '
        'highlightScheduleResponse 인텐트를 전달한다', (tester) async {
      final visited = <Map<String, Object?>>[];
      final router = _spyRouter(
        visited: visited,
        home: const Scaffold(
          body: ScheduleChangeRequestSection(teacherId: _teacherId),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingScheduleChangeRequestsProvider(_teacherId).overrideWith(
              (ref) async => [
                _pendingEvent(
                  id: 'evt_1',
                  actorId: 'student_1',
                  subscriptionId: 'sub_test_1',
                  sessionNumber: 3,
                ),
              ],
            ),
            todayRequestsProvider(
              _teacherId,
            ).overrideWith((ref) async => const []),
            // 카드 역조회에 아무 결과가 없음(갱신/교사 직접 제안) — fallback 경로.
            lessonRequestIdBySubscriptionProvider(
              'sub_test_1',
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 학생 이름(김민준 — studentNameMapProvider 기본값)이 표시된다.
      expect(find.text('김민준'), findsOneWidget);

      await tester.tap(find.text('김민준'));
      await tester.pumpAndSettle();

      expect(visited, hasLength(1));
      expect(visited.single['route'], 'subscriptionDetail');
      expect(visited.single['id'], 'sub_test_1');
      expect(visited.single['session'], '3');
      final extra = visited.single['extra'] as Map<String, dynamic>?;
      expect(extra?['viewerRole'], 'teacher');
      expect(extra?['highlightScheduleResponse'], isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('연결된 원 요청이 있으면 requestDetail(요청 스레드) 로 이동한다', (tester) async {
      final visited = <Map<String, Object?>>[];
      final router = _spyRouter(
        visited: visited,
        home: const Scaffold(
          body: ScheduleChangeRequestSection(teacherId: _teacherId),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingScheduleChangeRequestsProvider(_teacherId).overrideWith(
              (ref) async => [
                _pendingEvent(
                  id: 'evt_linked',
                  actorId: 'student_1',
                  subscriptionId: 'sub_linked_1',
                  sessionNumber: 3,
                ),
              ],
            ),
            todayRequestsProvider(
              _teacherId,
            ).overrideWith((ref) async => const []),
            // ScheduleConfirmationCard 역조회가 원 요청을 찾은 경우.
            lessonRequestIdBySubscriptionProvider(
              'sub_linked_1',
            ).overrideWith((ref) async => 'ulr_99'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('김민준'), findsOneWidget);

      await tester.tap(find.text('김민준'));
      await tester.pumpAndSettle();

      expect(visited, hasLength(1));
      expect(visited.single['route'], 'requestDetail');
      expect(visited.single['id'], 'ulr_99');
      final extra = visited.single['extra'] as Map<String, dynamic>?;
      expect(extra?['viewerRole'], 'teacher');
      expect(extra?['highlightScheduleResponse'], isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('subscriptionId 가 없으면 탭해도 이동하지 않는다', (tester) async {
      final visited = <Map<String, Object?>>[];
      final router = _spyRouter(
        visited: visited,
        home: const Scaffold(
          body: ScheduleChangeRequestSection(teacherId: _teacherId),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingScheduleChangeRequestsProvider(_teacherId).overrideWith(
              (ref) async => [
                _pendingEvent(
                  id: 'evt_2',
                  actorId: 'student_2',
                  subscriptionId: null,
                  sessionNumber: null,
                ),
              ],
            ),
            todayRequestsProvider(
              _teacherId,
            ).overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 학생 이름(이서현 — studentNameMapProvider 기본값)이 표시된다.
      expect(find.text('이서현'), findsOneWidget);

      await tester.tap(find.text('이서현'));
      await tester.pumpAndSettle();

      expect(visited, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
