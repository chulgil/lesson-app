// #930 / #112 — Student role card must display the invite pre-badge.
// UXC-13: 문구는 "초대 필요" → "초대코드 선택사항" 으로 완화됐고, 배지의
// 존재 자체는 유지된다 (검증은 리터럴이 아니라 상수 기준).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/role_select_screen.dart';

class _StubAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      AuthNeedsRole(userId: 'u1', name: '테스트', email: 't@test.com');
}

void main() {
  Future<void> pumpRoleSelect(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const RoleSelectScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('#112 학생 역할 카드에 초대코드 배지가 표시된다', (tester) async {
    await pumpRoleSelect(tester);

    expect(
      find.text(AppStrings.roleSelectStudentInviteBadge),
      findsOneWidget,
      reason: '학생 카드에만 초대코드 배지가 있어야 함',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('#112 선생님·학부모 역할 카드에는 배지가 없다', (tester) async {
    await pumpRoleSelect(tester);

    // Badge text appears exactly once (only on student card)
    expect(find.text(AppStrings.roleSelectStudentInviteBadge), findsOneWidget);

    // All three role cards still render
    expect(find.text(AppStrings.roleSelectTeacher), findsOneWidget);
    expect(find.text(AppStrings.roleSelectStudent), findsOneWidget);
    expect(find.text(AppStrings.roleSelectParent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1104 소요시간 안내 캡션("약 3분이면 끝나요")을 표시한다', (tester) async {
    await pumpRoleSelect(tester);

    expect(find.text(AppStrings.onboardingDurationCaption), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // #1267 — QR 스캔으로 온 신규 사용자는 역할 카드를 고르지 않고 바로 스캔으로
  // 시작할 수 있다. 필수 약관 동의 전에는 다른 카드들처럼 비활성 상태다.
  testWidgets('#1267 "QR 코드로 시작하기" 진입점이 있고, 약관 미동의 시 비활성이다', (tester) async {
    await pumpRoleSelect(tester);

    final scanEntry = find.widgetWithText(
      TextButton,
      AppStrings.roleSelectScanEntryLabel,
    );
    expect(scanEntry, findsOneWidget);
    expect(tester.widget<TextButton>(scanEntry).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1267 필수 약관에 동의하면 "QR 코드로 시작하기"가 활성화된다', (tester) async {
    await pumpRoleSelect(tester);

    // "전체 동의" tap satisfies both required terms in one go (mirrors
    // TermsAgreementSection._toggleAll — no Material Checkbox, custom
    // PencilBox affordance behind the label InkWell).
    await tester.tap(find.text(AppStrings.authTermsSelectAll));
    await tester.pumpAndSettle();

    final scanEntry = find.widgetWithText(
      TextButton,
      AppStrings.roleSelectScanEntryLabel,
    );
    expect(tester.widget<TextButton>(scanEntry).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
