// #977 — UserRole.onboardingRoute is the SSOT shared by RoleSelectScreen's
// multi-discipline gate and DisciplineSelectionScreen. It must stay
// byte-identical to the prior inline switch in RoleSelectScreen._goToOnboarding
// (teacher→profile-setup, student→signup-blocked, parent→invite-code).
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/extensions/user_role_visuals.dart';

void main() {
  group('UserRole.onboardingRoute (#977 byte-identity)', () {
    test('teacher → teacherProfileSetup', () {
      expect(UserRole.teacher.onboardingRoute, AppRoutes.teacherProfileSetup);
    });

    test('student → studentSignupBlocked (PASS 본인인증 통합 전 안전망)', () {
      expect(UserRole.student.onboardingRoute, AppRoutes.studentSignupBlocked);
    });

    test('parent → parentInviteCode', () {
      expect(UserRole.parent.onboardingRoute, AppRoutes.parentInviteCode);
    });
  });
}
