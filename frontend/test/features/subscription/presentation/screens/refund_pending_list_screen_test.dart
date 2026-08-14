import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/schedule/schedule_facade.dart'
    show studentNameMapProvider;
import 'package:lessonaza/features/subscription/domain/entities/refund_request.dart';
import 'package:lessonaza/features/subscription/presentation/providers/refund_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/refund_pending_list_screen.dart';

const _teacherId = 'teacher_1';

RefundRequest _pending({required String id, required String subscriptionId}) {
  return RefundRequest(
    id: id,
    subscriptionId: subscriptionId,
    studentId: 'student_1',
    teacherId: _teacherId,
    bankName: '신한은행',
    accountNumber: '110-123-456789',
    accountHolder: '홍길동',
    requestedAt: DateTime(2026, 8, 14),
  );
}

void main() {
  testWidgets('빈 상태는 EmptyStateWidget 을 렌더한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => _teacherId),
          teacherPendingRefundRequestsProvider(
            _teacherId,
          ).overrideWith((ref) async => <RefundRequest>[]),
          studentNameMapProvider.overrideWith((ref) => <String, String>{}),
        ],
        child: const MaterialApp(home: RefundPendingListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('환불 대기 항목이 없습니다.'), findsOneWidget);
  });

  testWidgets('요청 목록을 렌더하고 탭하면 수강권 상세로 이동한다', (tester) async {
    final visited = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) => const RefundPendingListScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscriptionDetail,
          builder: (ctx, state) {
            visited.add(state.pathParameters['id']!);
            return const Scaffold(body: Text('detail'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => _teacherId),
          teacherPendingRefundRequestsProvider(_teacherId).overrideWith(
            (ref) async => [_pending(id: 'r1', subscriptionId: 'sub_1')],
          ),
          studentNameMapProvider.overrideWith(
            (ref) => <String, String>{'student_1': '김민수'},
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('김민수'), findsOneWidget);
    expect(find.text('환불 요청됨'), findsOneWidget);

    await tester.tap(find.text('김민수'));
    await tester.pumpAndSettle();

    expect(visited, contains('sub_1'));
  });
}
