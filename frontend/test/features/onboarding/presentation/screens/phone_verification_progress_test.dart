import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/phone_verification_screen.dart';

/// #1143 회귀: 전화인증 화면이 폐기된 온보딩 선형 진행바(전화인증 -> 프로필설정 ->
/// 튜토리얼)를 그대로 표시했다. teacher 튜토리얼은 삭제됐고(#1082), 정식 온보딩
/// SSOT(#1104)는 역할 -> 분야 -> 프로필 -> 첫가용시간 4단계이며, 전화인증은 그 안에
/// 없다(온보딩 완료 후 선택 게이트/퀘스트). 따라서 이 화면은 온보딩 스텝 진행바를
/// 보여주면 안 된다.
/// (RED: 진행바 제거 전엔 프로필설정/튜토리얼 스텝 라벨이 화면에 남아 있다.)
void main() {
  Future<void> pumpPhoneVerification(
    WidgetTester tester, {
    String trigger = 'gate',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: PhoneVerificationScreen(trigger: trigger),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('전화인증 화면은 폐기된 온보딩 진행바(프로필설정/튜토리얼 스텝)를 표시하지 않는다', (tester) async {
    await pumpPhoneVerification(tester);

    // 폐기된 스텝 라벨이 화면에 없어야 한다.
    expect(
      find.text(AppStrings.onboardingProfileSetup),
      findsNothing,
      reason: '전화인증은 온보딩 선형 스텝이 아니므로 프로필설정 스텝 라벨이 없어야 한다',
    );
    expect(
      find.text(AppStrings.onboardingTutorial),
      findsNothing,
      reason: 'teacher 튜토리얼은 삭제됨(#1082) — 튜토리얼 스텝 라벨이 없어야 한다',
    );

    // 화면 본문은 정상 렌더 (전화번호 입력 필드 + 발송 버튼 노출).
    expect(find.byType(TextField), findsWidgets);
    expect(
      find.widgetWithText(ElevatedButton, AppStrings.phoneVerifyButtonSend),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
