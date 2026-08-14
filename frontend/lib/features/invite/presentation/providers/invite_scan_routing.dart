// #1267 — QR/코드 대상 역할 사전결정: scan resolution 후 어디로 갈지 결정하는
// 순수 함수. BuildContext/Riverpod 에 의존하지 않아 위젯 없이 단위 테스트
// 가능 — app_router.dart 의 resolveAuthRedirect 와 동일한 패턴.

import '../../../auth/domain/entities/user_role.dart';
import '../../../profile/domain/entities/invite.dart';
import '../extensions/invite_target_role_routing.dart';

/// Where a resolved [Invite] should route to, given whether the session is
/// brand-new (no role chosen yet) and — if not — the account's current role.
sealed class InviteScanRoute {
  const InviteScanRoute();
}

/// Legacy invite (no target role) or a target-role invite scanned by an
/// account whose role already matches the target — proceed to the normal
/// [AppRoutes.inviteConfirm] connection-request flow, unchanged.
class InviteScanConfirm extends InviteScanRoute {
  const InviteScanConfirm();
}

/// New/role-less session (`AuthNeedsRole`) scanning a target-role invite —
/// skip RoleSelectScreen entirely and land on the target role's onboarding
/// entry. `student`/`parent` targets reuse the existing invite-code
/// onboarding screens (code prefilled, no manual entry); `teacher` never
/// creates a connection request — the invite becomes a referral record once
/// [InviteRepository.useInvite] is called.
class InviteScanNewUserOnboarding extends InviteScanRoute {
  const InviteScanNewUserOnboarding({
    required this.role,
    required this.onboardingRoute,
    required this.createsConnectionRequest,
  });

  final UserRole role;
  final String onboardingRoute;

  /// false only for [UserRole.teacher] — referral, no connection.
  final bool createsConnectionRequest;
}

/// Existing account whose role does not match the invite's target role
/// (e.g. a parent scanning a student-targeted invite). Blocked — the caller
/// still routes to [AppRoutes.inviteConfirm] so it can reuse the existing
/// "cannot connect" blocked-content pattern with target-role-specific copy.
class InviteScanRoleMismatch extends InviteScanRoute {
  const InviteScanRoleMismatch({required this.expected, required this.actual});

  final InviteTargetRole expected;
  final UserRole actual;
}

/// Decides the scan routing outcome.
///
/// [isNewSession] is true when the scanner has no role yet (`AuthNeedsRole`)
/// — the only state from which [InviteScanNewUserOnboarding] applies.
/// [currentUserRole] is the scanner's role for any other (existing) session;
/// pass null only when [isNewSession] is true.
InviteScanRoute resolveInviteScanRoute({
  required InviteTargetRole? targetRole,
  required bool isNewSession,
  UserRole? currentUserRole,
}) {
  if (targetRole == null) return const InviteScanConfirm();

  if (isNewSession) {
    return InviteScanNewUserOnboarding(
      role: targetRole.asUserRole,
      onboardingRoute: targetRole.onboardingRoute,
      createsConnectionRequest: targetRole != InviteTargetRole.teacher,
    );
  }

  if (currentUserRole == null) {
    throw ArgumentError(
      'resolveInviteScanRoute: currentUserRole is required when '
      'isNewSession is false',
    );
  }

  if (currentUserRole == targetRole.asUserRole) {
    return const InviteScanConfirm();
  }

  return InviteScanRoleMismatch(expected: targetRole, actual: currentUserRole);
}
