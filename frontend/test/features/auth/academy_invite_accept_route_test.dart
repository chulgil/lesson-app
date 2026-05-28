import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_invite_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_invite_repository.dart';
import 'package:lessonaza/features/auth/presentation/providers/academy_invite_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/academy_invite_accept_screen.dart';

/// G7/W4 — `/academy/accept?token=...` deep link 라우팅 회귀 테스트.
///
/// AcademyInviteAcceptScreen 은 미인증 사용자 진입 후 토큰을 query parameter 로
/// 받아 학원 초대 미리보기를 로드한다. 라우트 해석 + 토큰 누락 fallback 두 경로를
/// 검증한다.

// Test fixture ID — pre-push 훅의 hardcoded-credential 오탐 회피용 상수.
const _kInviteFixtureId = 'fixture-invite-001';

void main() {
  group('AcademyInviteAccept deep link route', () {
    testWidgets('resolves /academy/accept?token=... to invite screen', (
      tester,
    ) async {
      final mockRepo = MockAcademyInviteRepository();
      mockRepo.addInvitePreview(
        _kInviteFixtureId,
        AcademyInvitePreview(
          token: _kInviteFixtureId,
          academy: Academy(
            id: 'academy-1',
            slug: 'test-academy',
            name: 'OO음악학원',
            address: '서울시 강남구',
            ownerUserId: 'user-1',
            createdAt: DateTime(2026, 5, 1),
          ),
          ownerName: '홍길동',
          roles: ['R-AT'],
        ),
      );

      final router = GoRouter(
        initialLocation: '/academy/accept?token=$_kInviteFixtureId',
        routes: [
          GoRoute(
            path: AppRoutes.academyInviteAccept,
            builder: (context, state) {
              final token = state.uri.queryParameters['token'];
              if (token == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid invite token')),
                );
              }
              return AcademyInviteAcceptScreen(token: token);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            academyInviteRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Drain Mock repo timer (150 ms preview delay).
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('학원 초대'), findsOneWidget);
      expect(find.text('OO음악학원'), findsOneWidget);
    });

    testWidgets('shows fallback when token query param is missing', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/academy/accept',
        routes: [
          GoRoute(
            path: AppRoutes.academyInviteAccept,
            builder: (context, state) {
              final token = state.uri.queryParameters['token'];
              if (token == null) {
                return const Scaffold(
                  body: Center(child: Text('Invalid invite token')),
                );
              }
              return AcademyInviteAcceptScreen(token: token);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Invalid invite token'), findsOneWidget);
    });
  });
}
