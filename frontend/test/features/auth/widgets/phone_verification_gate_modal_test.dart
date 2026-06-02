import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/presentation/widgets/phone_verification_gate_modal.dart';

/// #430 G1 #5 — E3 phone verification gate 모달 스모크 테스트.
///
/// 가입 직후 미인증 선생님이 수강권 발급을 시도하면 백엔드가
/// `PhoneVerificationRequiredException` 을 던지고, FE 가
/// [PhoneVerificationGate.show] 를 호출한다. 본 테스트는 모달 UI 가
/// 라우터 컨텍스트에서 크래시 없이 렌더되고 CTA 가 모두 노출되는지
/// 확인한다.
void main() {
  group('PhoneVerificationGate', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder:
                (context, state) => Scaffold(
                  body: Builder(
                    builder:
                        (context) => Center(
                          child: ElevatedButton(
                            onPressed:
                                () => PhoneVerificationGate.show(context),
                            child: const Text('open'),
                          ),
                        ),
                  ),
                ),
          ),
          GoRoute(
            path: AppRoutes.teacherPhoneVerification,
            builder:
                (context, state) =>
                    const Scaffold(body: Text('verification page')),
          ),
        ],
      );
    });

    testWidgets('opens dialog with title body reward and both CTAs', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.phoneVerificationGateTitle), findsOneWidget);
      expect(find.text(AppStrings.phoneVerificationGateBody), findsOneWidget);
      expect(
        find.text(AppStrings.phoneVerificationGateRewardLine),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.phoneVerificationGateCtaVerifyNow),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.phoneVerificationGateCtaLater),
        findsOneWidget,
      );
    });

    testWidgets('"나중에" dismisses dialog with false result', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.phoneVerificationGateCtaLater));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text(AppStrings.phoneVerificationGateTitle), findsNothing);
    });

    testWidgets('"지금 인증하기" routes to teacher phone verification', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.phoneVerificationGateCtaVerifyNow));
      await tester.pumpAndSettle();

      expect(find.text('verification page'), findsOneWidget);
      expect(find.text(AppStrings.phoneVerificationGateTitle), findsNothing);
    });
  });
}
