// #1267 — QR/코드 대상 역할 사전결정: InviteTargetRole -> UserRole/onboarding
// route 매핑. flutter-architecture.md 상 domain 은 routing 을 몰라야 하므로
// (AppRoutes/UserRole 의존은 presentation 전용) 이 파일에서만 변환한다.

import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../profile/domain/entities/invite.dart';

extension InviteTargetRoleRouting on InviteTargetRole {
  /// The app-wide [UserRole] this invite target corresponds to.
  UserRole get asUserRole {
    switch (this) {
      case InviteTargetRole.teacher:
        return UserRole.teacher;
      case InviteTargetRole.student:
        return UserRole.student;
      case InviteTargetRole.parent:
        return UserRole.parent;
    }
  }

  /// Onboarding entry a brand-new (role-less) scanner should land on.
  ///
  /// Mirrors [UserRoleVisuals.onboardingRoute] except for [student]: normal
  /// student sign-up is blocked pending PASS integration
  /// (`studentSignupBlocked`), but an invite-carried code is the official
  /// invite-based sign-up path (Phase 2 spec §3), so it goes straight to
  /// `studentInviteCode` instead.
  String get onboardingRoute {
    switch (this) {
      case InviteTargetRole.teacher:
        return AppRoutes.teacherProfileSetup;
      case InviteTargetRole.student:
        return AppRoutes.studentInviteCode;
      case InviteTargetRole.parent:
        return AppRoutes.parentInviteCode;
    }
  }
}
