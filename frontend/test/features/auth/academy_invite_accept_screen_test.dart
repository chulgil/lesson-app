import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/academy/domain/entities/academy.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_invite_repository.dart';
import 'package:lessonaza/features/auth/presentation/providers/academy_invite_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/academy_invite_accept_screen.dart';

/// Spy repository that records calls without delay.
class _SpyInviteRepository implements AcademyInviteRepository {
  _SpyInviteRepository(this.preview);

  final AcademyInvitePreview preview;
  String? acceptedToken;
  bool? acceptedConsent;
  String? rejectedToken;

  @override
  Future<AcademyInvitePreview> getInvitePreview(String token) async => preview;

  @override
  Future<void> acceptInvite(
    String token, {
    required bool publicPageConsent,
  }) async {
    acceptedToken = token;
    acceptedConsent = publicPageConsent;
  }

  @override
  Future<void> rejectInvite(String token, {String? reason}) async {
    rejectedToken = token;
  }
}

/// G8/W4 — AcademyInviteAcceptScreen 회귀 테스트.
///
/// 학원 정보 + 부여될 권한 + 공개 동의 checkbox + 수락/거절 버튼이 모두 노출되고,
/// 동의 토글 후 수락 시 repository.acceptInvite(token, publicPageConsent: true)
/// 가 호출되는지 검증.
void main() {
  late _SpyInviteRepository spy;
  const testToken = 'invite-token-abc';

  setUp(() {
    spy = _SpyInviteRepository(
      AcademyInvitePreview(
        token: testToken,
        academy: Academy(
          id: 'academy-1',
          slug: 'oo-music',
          name: 'OO음악학원',
          address: '서울시 강남구 테헤란로 1',
          ownerUserId: 'user-1',
          createdAt: DateTime(2026, 5, 1),
        ),
        ownerName: '홍길동',
        roles: ['R-AO', 'R-AT'],
      ),
    );
  });

  Widget buildSubject() {
    final router = GoRouter(
      initialLocation: '/academy/accept?token=$testToken',
      routes: [
        GoRoute(
          path: AppRoutes.academyInviteAccept,
          builder:
              (context, state) => AcademyInviteAcceptScreen(token: testToken),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('home-stub')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [academyInviteRepositoryProvider.overrideWithValue(spy)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AcademyInviteAcceptScreen', () {
    testWidgets('renders academy info + roles + consent + actions', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('OO음악학원'), findsOneWidget);
      expect(find.text('서울시 강남구 테헤란로 1'), findsOneWidget);
      expect(find.text('대표: 홍길동'), findsOneWidget);
      expect(find.text('- R-AO'), findsOneWidget);
      expect(find.text('- R-AT'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('수락'), findsOneWidget);
      expect(find.text('거절'), findsOneWidget);
    });

    testWidgets('accept passes consent=true to repository after toggle', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('수락'));
      await tester.pump();
      await tester.pump();

      expect(spy.acceptedToken, equals(testToken));
      expect(spy.acceptedConsent, isTrue);
    });

    testWidgets('reject calls repository.rejectInvite', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('거절'));
      await tester.pump();
      await tester.pump();

      expect(spy.rejectedToken, equals(testToken));
    });
  });
}
