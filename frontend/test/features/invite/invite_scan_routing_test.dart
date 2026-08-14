// #1267 — QR/코드 대상 역할 사전결정: resolveInviteScanRoute 순수 함수 매트릭스.
// 대상 3종(선생님/학생/학부모) × {신규, 기존 일치, 기존 불일치} + 레거시 회귀.
// app_router.dart 의 resolveAuthRedirect 테스트와 동일한 위젯-프리 패턴.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/invite/presentation/extensions/invite_target_role_routing.dart';
import 'package:lessonaza/features/invite/presentation/providers/invite_scan_routing.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';

void main() {
  group('resolveInviteScanRoute — legacy invite (no target role)', () {
    test('always InviteScanConfirm regardless of session', () {
      final result = resolveInviteScanRoute(
        targetRole: null,
        isNewSession: true,
      );
      expect(result, isA<InviteScanConfirm>());
    });

    test('existing account also just confirms (AC4 — 레거시 호환)', () {
      final result = resolveInviteScanRoute(
        targetRole: null,
        isNewSession: false,
        currentUserRole: UserRole.teacher,
      );
      expect(result, isA<InviteScanConfirm>());
    });
  });

  group('resolveInviteScanRoute — new session (AuthNeedsRole)', () {
    test('teacher target -> onboards to teacher, no connection request', () {
      final result = resolveInviteScanRoute(
        targetRole: InviteTargetRole.teacher,
        isNewSession: true,
      );
      final decision = result as InviteScanNewUserOnboarding;
      expect(decision.role, UserRole.teacher);
      expect(decision.onboardingRoute, AppRoutes.teacherProfileSetup);
      expect(decision.createsConnectionRequest, isFalse);
    });

    test('student target -> onboards to student invite-code path', () {
      final result = resolveInviteScanRoute(
        targetRole: InviteTargetRole.student,
        isNewSession: true,
      );
      final decision = result as InviteScanNewUserOnboarding;
      expect(decision.role, UserRole.student);
      expect(decision.onboardingRoute, AppRoutes.studentInviteCode);
      expect(decision.createsConnectionRequest, isTrue);
    });

    test('parent target -> onboards to parent invite-code path', () {
      final result = resolveInviteScanRoute(
        targetRole: InviteTargetRole.parent,
        isNewSession: true,
      );
      final decision = result as InviteScanNewUserOnboarding;
      expect(decision.role, UserRole.parent);
      expect(decision.onboardingRoute, AppRoutes.parentInviteCode);
      expect(decision.createsConnectionRequest, isTrue);
    });
  });

  group('resolveInviteScanRoute — existing account, role matches target', () {
    for (final role in InviteTargetRole.values) {
      test('$role scanned by a matching account -> InviteScanConfirm', () {
        final result = resolveInviteScanRoute(
          targetRole: role,
          isNewSession: false,
          currentUserRole: role.asUserRole,
        );
        expect(result, isA<InviteScanConfirm>());
      });
    }
  });

  group(
    'resolveInviteScanRoute — existing account, role mismatches target',
    () {
      test('parent scans a student-targeted invite -> blocked (대리 가입 시도)', () {
        final result = resolveInviteScanRoute(
          targetRole: InviteTargetRole.student,
          isNewSession: false,
          currentUserRole: UserRole.parent,
        );
        final decision = result as InviteScanRoleMismatch;
        expect(decision.expected, InviteTargetRole.student);
        expect(decision.actual, UserRole.parent);
      });

      test('teacher scans a parent-targeted invite -> blocked', () {
        final result = resolveInviteScanRoute(
          targetRole: InviteTargetRole.parent,
          isNewSession: false,
          currentUserRole: UserRole.teacher,
        );
        expect(result, isA<InviteScanRoleMismatch>());
      });

      test('student scans a teacher-targeted (referral) invite -> blocked', () {
        final result = resolveInviteScanRoute(
          targetRole: InviteTargetRole.teacher,
          isNewSession: false,
          currentUserRole: UserRole.student,
        );
        expect(result, isA<InviteScanRoleMismatch>());
      });
    },
  );

  group('resolveInviteScanRoute — contract violation', () {
    test('existing session without currentUserRole throws (caller bug)', () {
      expect(
        () => resolveInviteScanRoute(
          targetRole: InviteTargetRole.student,
          isNewSession: false,
        ),
        throwsArgumentError,
      );
    });
  });
}
