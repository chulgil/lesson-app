// Auth and onboarding route definitions

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/notebook/notebook_surfaces.dart';
import '../../../features/auth/presentation/screens/academy_invite_accept_screen.dart';
import '../../../features/auth/presentation/screens/academy_invite_expired_screen.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/parent_invite_code_screen.dart';
import '../../../features/auth/presentation/screens/role_select_screen.dart';
import '../../../features/auth/presentation/screens/student_invite_code_screen.dart';
import '../../../features/onboarding/presentation/screens/first_availability_setup_screen.dart';
import '../../../features/onboarding/presentation/screens/onboarding_category_preview_screen.dart';
import '../../../features/onboarding/presentation/screens/phone_verification_screen.dart';
import '../../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../../features/onboarding/presentation/screens/student_profile_setup_screen.dart';
import '../../../features/onboarding/presentation/screens/student_signup_blocked_screen.dart';
import '../../../features/onboarding/presentation/screens/student_tutorial_screen.dart';
import '../../../features/onboarding/presentation/screens/tutorial_screen.dart';
import '../app_routes.dart';

/// Auth and onboarding routes
List<GoRoute> authRoutes = [
  // Login
  GoRoute(
    path: AppRoutes.login,
    name: 'login',
    builder: (context, state) => const LoginScreen(),
  ),

  // Role selection (after first OAuth signup) — also collects terms inline.
  // 정책: phone_verification_policy.md §2.3 — 약관 동의 별도 페이지 제거.
  // 종전 `/terms-agreement` 경로는 deprecated 되고 RoleSelectScreen 안에
  // TermsAgreementSection 으로 통합됨.
  GoRoute(
    path: AppRoutes.roleSelect,
    name: 'roleSelect',
    builder: (context, state) => const RoleSelectScreen(),
  ),

  // Parent Invite Code
  GoRoute(
    path: AppRoutes.parentInviteCode,
    name: 'parentInviteCode',
    builder: (context, state) => const ParentInviteCodeScreen(),
  ),

  // Student Invite Code
  GoRoute(
    path: AppRoutes.studentInviteCode,
    name: 'studentInviteCode',
    builder: (context, state) => const StudentInviteCodeScreen(),
  ),

  // Teacher Onboarding - Phone Verification
  GoRoute(
    path: AppRoutes.teacherPhoneVerification,
    name: 'teacherPhoneVerification',
    builder:
        (context, state) => PhoneVerificationScreen(
          // #695 §5.5 — 'gate' when routed from the E3 gate modal; quest otherwise.
          trigger: state.uri.queryParameters['trigger'] ?? 'quest',
        ),
  ),

  // Teacher Onboarding - Profile Setup
  GoRoute(
    path: AppRoutes.teacherProfileSetup,
    name: 'teacherProfileSetup',
    builder: (context, state) => const ProfileSetupScreen(),
  ),

  // Teacher Onboarding - Tutorial
  GoRoute(
    path: AppRoutes.teacherTutorial,
    name: 'teacherTutorial',
    builder: (context, state) => const TutorialScreen(),
  ),

  // Teacher Onboarding - First Availability Quest (#422)
  GoRoute(
    path: AppRoutes.teacherFirstAvailability,
    name: 'teacherFirstAvailability',
    builder: (context, state) => const FirstAvailabilitySetupScreen(),
  ),

  // Teacher Onboarding - Step 2.5 Category Preview (W4 Task 4.2)
  // spec §9.2 — 5묶음 카테고리 한 화면 미리보기 1회 노출.
  GoRoute(
    path: AppRoutes.onboardingCategoryPreview,
    name: 'onboardingCategoryPreview',
    builder: (context, state) => const OnboardingCategoryPreviewScreen(),
  ),

  // Student Onboarding - Profile Setup
  GoRoute(
    path: AppRoutes.studentProfileSetup,
    name: 'studentProfileSetup',
    builder: (context, state) => const StudentProfileSetupScreen(),
  ),

  // Student Onboarding - Signup Blocked (임시 안전망 — PASS 본인인증 통합 전)
  // 정책: phone_verification_policy.md §3.2 — 만 14세 검증 부재로 인한 차단.
  GoRoute(
    path: AppRoutes.studentSignupBlocked,
    name: 'studentSignupBlocked',
    builder: (context, state) => const StudentSignupBlockedScreen(),
  ),

  // Student Onboarding - Tutorial
  GoRoute(
    path: AppRoutes.studentTutorial,
    name: 'studentTutorial',
    builder: (context, state) => const StudentTutorialScreen(),
  ),

  // Academy Invite Accept
  GoRoute(
    path: AppRoutes.academyInviteAccept,
    name: 'academyInviteAccept',
    builder: (context, state) {
      final token = state.uri.queryParameters['token'];
      if (token == null) {
        return const NotebookScreenScaffold(
          body: Center(child: Text('Invalid invite token')),
        );
      }
      return AcademyInviteAcceptScreen(token: token);
    },
  ),

  // Academy Invite Expired/Invalid
  GoRoute(
    path: AppRoutes.academyInviteExpired,
    name: 'academyInviteExpired',
    builder: (context, state) {
      return AcademyInviteExpiredScreen(
        errorCode: state.uri.queryParameters['code'],
        errorMessage: state.uri.queryParameters['message'],
      );
    },
  ),
];
