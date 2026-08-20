// UXB-2 #1289 — 초대 딥링크 role-skip 의 라우팅 계약.
//
// 6자리 초대 코드는 항상 학생 연결이므로, 코드를 들고 온 역할 미확정 사용자는
// roleSelect·studentSignupBlocked 를 건너뛰고 학생 초대코드 화면으로 직행한다.
// 코드가 없는 일반 가입 흐름은 한 줄도 달라지지 않아야 한다 (아래 unchanged 군).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/router/app_router.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';

const _code = '424242';
const _needsRole = AuthNeedsRole(userId: 'u', name: 'n', email: 'e');

void main() {
  group('resolveAuthRedirect — 초대 딥링크 role-skip (UXB-2)', () {
    test('역할 미확정 + 코드 보유 → 학생 초대코드 화면으로 직행', () {
      expect(
        resolveAuthRedirect(
          _needsRole,
          '/teacher/home', // 임의의 보호 경로
          pendingInviteCode: _code,
        ),
        AppRoutes.studentInviteCode,
      );
    });

    test('로그인 직후(OAuth) 도 roleSelect 대신 학생 초대코드 화면', () {
      // 로그아웃 상태에서 링크를 열면 login 을 거친다. 여기서 roleSelect 로
      // 튕기면 "2화면 감소" AC 가 깨진다.
      expect(
        resolveAuthRedirect(
          _needsRole,
          AppRoutes.login,
          pendingInviteCode: _code,
        ),
        AppRoutes.studentInviteCode,
      );
    });

    test('딥링크 착지 경로(/invite/code) 도 학생 초대코드 화면으로 승격', () {
      expect(
        resolveAuthRedirect(
          _needsRole,
          AppRoutes.inviteCode,
          pendingInviteCode: _code,
        ),
        AppRoutes.studentInviteCode,
      );
    });

    test('목적지에 도착하면 더는 redirect 하지 않는다 (무한 루프 방지)', () {
      expect(
        resolveAuthRedirect(
          _needsRole,
          AppRoutes.studentInviteCode,
          pendingInviteCode: _code,
        ),
        isNull,
      );
    });

    test('보조 링크 탈출구: roleSelect 는 코드가 있어도 그대로 허용', () {
      // 화면의 "선생님·학부모로 시작하기" 는 코드를 비우고 이동하지만,
      // 비우기 전에 redirect 가 평가되어도 튕기지 않아야 한다.
      expect(
        resolveAuthRedirect(
          _needsRole,
          AppRoutes.roleSelect,
          pendingInviteCode: _code,
        ),
        isNull,
      );
    });

    test('#1267 QR 스캐너 화이트리스트는 코드가 있어도 유지', () {
      expect(
        resolveAuthRedirect(
          _needsRole,
          AppRoutes.inviteScan,
          pendingInviteCode: _code,
        ),
        isNull,
      );
    });
  });

  group('resolveAuthRedirect — 코드 없는 흐름 불변 (UXB-2 경계)', () {
    test('코드 없으면 기존대로 roleSelect', () {
      expect(
        resolveAuthRedirect(_needsRole, '/teacher/home'),
        AppRoutes.roleSelect,
      );
      expect(
        resolveAuthRedirect(
          _needsRole,
          '/teacher/home',
          pendingInviteCode: null,
        ),
        AppRoutes.roleSelect,
      );
    });

    test('코드 없으면 /invite/code 도 기존대로 roleSelect', () {
      expect(
        resolveAuthRedirect(_needsRole, AppRoutes.inviteCode),
        AppRoutes.roleSelect,
      );
    });

    test('미인증은 코드가 있어도 login 우선 (로그인 없이는 연결 불가)', () {
      expect(
        resolveAuthRedirect(
          const AuthUnauthenticated(),
          '/teacher/home',
          pendingInviteCode: _code,
        ),
        AppRoutes.login,
      );
    });

    test('역할이 이미 있으면(onboarding) 코드는 라우팅에 영향 없음', () {
      const onboarding = AuthNeedsOnboarding(
        userId: 'u',
        name: 'n',
        email: 'e',
        role: UserRole.student,
      );
      // 기존 온보딩 화이트리스트 그대로.
      expect(
        resolveAuthRedirect(
          onboarding,
          AppRoutes.studentInviteCode,
          pendingInviteCode: _code,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          onboarding,
          '/teacher/home',
          pendingInviteCode: _code,
        ),
        AppRoutes.roleSelect,
      );
    });

    test('인증 완료 사용자는 코드가 있어도 기존 경로 유지', () {
      const authed = AuthAuthenticated(
        userId: 'u',
        name: 'n',
        email: 'e',
        role: UserRole.teacher,
      );
      expect(
        resolveAuthRedirect(authed, '/teacher/home', pendingInviteCode: _code),
        isNull,
      );
    });

    test('로딩 중에는 코드가 있어도 판단하지 않는다', () {
      expect(
        resolveAuthRedirect(
          const AuthLoading(),
          '/teacher/home',
          pendingInviteCode: _code,
        ),
        isNull,
      );
    });
  });
}
