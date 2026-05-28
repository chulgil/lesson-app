import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_invite_repository.dart';
import 'package:lessonaza/features/auth/presentation/providers/academy_invite_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/academy_invite_accept_screen.dart';
import 'package:lessonaza/features/auth/presentation/screens/academy_invite_expired_screen.dart';

/// G9/W4 — 초대 만료/잘못된 토큰 화면 회귀 테스트.
///
/// (1) AcademyInviteExpiredScreen 이 errorCode 별로 다른 제목/부제를 표시한다.
/// (2) AcademyInviteAcceptScreen 이 preview 로드 실패 시 expired 화면으로 분기한다.
class _ThrowingInviteRepository implements AcademyInviteRepository {
  _ThrowingInviteRepository(this.error);

  final Exception error;

  @override
  Future<AcademyInvitePreview> getInvitePreview(String token) async {
    throw error;
  }

  @override
  Future<void> acceptInvite(
    String token, {
    required bool publicPageConsent,
  }) async {
    throw error;
  }

  @override
  Future<void> rejectInvite(String token, {String? reason}) async {
    throw error;
  }
}

void main() {
  group('AcademyInviteExpiredScreen', () {
    testWidgets('expired code shows expired title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AcademyInviteExpiredScreen(errorCode: 'expired'),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('초대 만료'), findsOneWidget);
      expect(find.text('초대 링크가 만료되었습니다.'), findsOneWidget);
      expect(find.text('학원에 다시 초대 요청을 해주세요.'), findsOneWidget);
      expect(find.text('홈으로 이동'), findsOneWidget);
    });

    testWidgets('unknown code shows invalid invite title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AcademyInviteExpiredScreen(errorCode: 'not_found'),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('유효하지 않은 초대'), findsOneWidget);
      expect(find.text('유효하지 않은 초대 링크입니다.'), findsOneWidget);
    });
  });

  group('AcademyInviteAcceptScreen error branch', () {
    testWidgets('expired token surfaces expired screen', (tester) async {
      final repo = _ThrowingInviteRepository(Exception('Invite token expired'));

      final router = GoRouter(
        initialLocation: '/academy/accept?token=tok',
        routes: [
          GoRoute(
            path: AppRoutes.academyInviteAccept,
            builder:
                (context, state) =>
                    const AcademyInviteAcceptScreen(token: 'tok'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [academyInviteRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('초대 만료'), findsOneWidget);
    });

    testWidgets('not-found token surfaces invalid invite screen', (
      tester,
    ) async {
      final repo = _ThrowingInviteRepository(
        Exception('Invite token not found'),
      );

      final router = GoRouter(
        initialLocation: '/academy/accept?token=tok',
        routes: [
          GoRoute(
            path: AppRoutes.academyInviteAccept,
            builder:
                (context, state) =>
                    const AcademyInviteAcceptScreen(token: 'tok'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [academyInviteRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('유효하지 않은 초대'), findsOneWidget);
    });
  });
}
