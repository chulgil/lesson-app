// #930 / #112 — Student role card must display "초대 필요" pre-badge.
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

  testWidgets('#112 학생 역할 카드에 "초대 필요" 배지가 표시된다', (tester) async {
    await pumpRoleSelect(tester);

    expect(
      find.text(AppStrings.roleSelectStudentInviteBadge),
      findsOneWidget,
      reason: '학생 카드에만 초대 필요 배지가 있어야 함',
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
}
