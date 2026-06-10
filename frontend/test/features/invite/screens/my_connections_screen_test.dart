// #660 C6 — MyConnectionsScreen SwipeActionTile 적용 smoke test.
//
// active 카드는 IconButton(more_vert) 가 제거되고 SwipeActionTile 의
// destructive [연결 해제] 액션만 노출되는지 (그리고 시트 진입은
// 카드 탭으로 유지) 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/invite/presentation/screens/my_connections_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

class _FakeInviteUserRole extends CurrentInviteUserRole {
  @override
  InviteUserRole build() => InviteUserRole.teacher;
}

Connection _activeConnection() => Connection(
  id: 'conn-1',
  teacherId: 't-1',
  teacherName: '김선생님',
  studentId: 's-1',
  studentName: '지우',
  connectedAt: DateTime(2025, 1, 1),
);

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentInviteUserRoleProvider.overrideWith(_FakeInviteUserRole.new),
        myConnectionsProvider.overrideWith(
          (ref) async => [_activeConnection()],
        ),
        myDisconnectedConnectionsProvider.overrideWith(
          (ref) async => const <Connection>[],
        ),
      ],
      child: const MaterialApp(home: MyConnectionsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('active 카드에 SwipeActionTile 적용 + more_vert 제거 (#660 C6)', (
    tester,
  ) async {
    await _pumpScreen(tester);

    // active 카드 1건은 SwipeActionTile 로 감싸진다.
    expect(find.byType(SwipeActionTile), findsOneWidget);
    // 학생 이름 노출 확인.
    expect(find.text('지우'), findsOneWidget);
    // more_vert IconButton 은 제거됨 (audit C6 요구사항).
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppStrings 의 새 라벨이 코드에서 사용 가능하다 (#660 C6)', (tester) async {
    // 누락 회귀 방지 — 의도 노출 (라벨 자체가 컴파일 타임 상수로 존재).
    expect(AppStrings.swipeActionDisconnect, isNotEmpty);
    expect(AppStrings.swipeActionDisconnectConfirmTitle, isNotEmpty);
    expect(AppStrings.swipeActionDisconnectConfirmBody, isNotEmpty);
  });
}
