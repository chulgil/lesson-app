// #1267 — QR 스캔으로 온 신규 학생 사용자는 코드를 이미 알고 있으므로 6자리
// 수동 입력 없이 자동 제출되어야 한다 (initialCode -> InviteCodeDigitInput
// 의 기존 deep-link prefill 경로 재사용, 새 코드 없음).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/student_invite_code_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

Invite _fakeInvite() => Invite(
  id: 'invite-1267-student',
  creatorId: 'teacher-1',
  creatorName: '김선생',
  creatorRole: InviteUserRole.teacher,
  inviteCode: '424242',
  inviteUrl: 'lessonapp://invite/424242',
  qrCodeData: 'lessonapp://invite/424242',
  status: InviteStatus.active,
  expiresAt: DateTime.now().add(const Duration(days: 6)),
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  targetRole: InviteTargetRole.student,
);

void main() {
  testWidgets('initialCode 가 주어지면 digit box 를 채우지 않고도 확인 화면으로 넘어간다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockDataModeProvider.overrideWithValue(true),
          inviteByCodeProvider(
            '424242',
          ).overrideWith((ref) async => _fakeInvite()),
        ],
        child: const MaterialApp(
          home: StudentInviteCodeScreen(initialCode: '424242'),
        ),
      ),
    );
    // Auto-submit runs on a post-frame callback — pumpAndSettle drains it.
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.inviteConnectionRequest), findsOneWidget);
    expect(find.text(AppStrings.inviteSendConnectionRequest), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialCode 없이 진입하면 기존처럼 빈 digit box 로 시작한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockDataModeProvider.overrideWithValue(true)],
        child: const MaterialApp(home: StudentInviteCodeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text(AppStrings.inviteConnectionRequest), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
